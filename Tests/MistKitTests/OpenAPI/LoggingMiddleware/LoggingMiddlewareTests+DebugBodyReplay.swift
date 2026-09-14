//
//  LoggingMiddlewareTests+DebugBodyReplay.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation
internal import HTTPTypes
internal import Logging
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension LoggingMiddlewareTests {
  /// At debug level the middleware reads a bounded prefix of every JSON
  /// response body to log it. The caller must still receive the *whole*
  /// body exactly once — a body over the cap previously came back partly
  /// consumed and failed with "attempted to create a second iterator".
  @Suite("Debug Body Replay", .disabled(if: Platform.isWindowsSwift62))
  internal struct DebugBodyReplay {
    private static func debugMiddleware() -> LoggingMiddleware {
      var logger = Logger(label: "com.brightdigit.MistKit.middleware.test") { _ in
        SwiftLogNoOpLogHandler()
      }
      logger.logLevel = .debug
      return LoggingMiddleware(logger: logger)
    }

    private static func intercept(
      _ middleware: LoggingMiddleware,
      returning responseBody: HTTPBody
    ) async throws -> Data {
      let request = HTTPRequest(
        method: .post,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/test"
      )
      let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))
      let next:
        (HTTPRequest, HTTPBody?, URL) async throws
          -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            var response = HTTPResponse(status: .ok)
            response.headerFields[.contentType] = "application/json;charset=utf-8"
            return (response, responseBody)
          }
      let (_, returnedBody) = try await middleware.intercept(
        request, body: nil, baseURL: baseURL, operationID: "test", next: next
      )
      return try await Data(collecting: try #require(returnedBody), upTo: .max)
    }

    @Test("debug level passes a JSON body larger than the log cap through intact")
    internal func largeBodyPassesThroughAtDebug() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        // Three times the 64 KiB cap, and not a multiple of it.
        let original = Data((0..<200_001).map { UInt8($0 % 251) })
        let collected = try await Self.intercept(
          Self.debugMiddleware(), returning: HTTPBody(original)
        )
        #expect(collected == original)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("debug level replays a chunked stream of unknown length in order")
    internal func chunkedStreamReplaysInOrder() async throws {
      let chunks: [Data] = (0..<10).map { index in
        Data(repeating: UInt8(0x30 + index), count: 20_000)
      }
      let expected = chunks.reduce(Data(), +)
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let stream = AsyncThrowingStream<HTTPBody.ByteChunk, any Error> { continuation in
          for chunk in chunks {
            continuation.yield(ArraySlice(chunk))
          }
          continuation.finish()
        }
        let collected = try await Self.intercept(
          Self.debugMiddleware(), returning: HTTPBody(stream, length: .unknown)
        )
        #expect(collected == expected)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    @Test("debug level still returns a body smaller than the cap unchanged")
    internal func smallBodyPassesThroughAtDebug() async throws {
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let original = Data(#"{"records":[]}"#.utf8)
        let collected = try await Self.intercept(
          Self.debugMiddleware(), returning: HTTPBody(original)
        )
        #expect(collected == original)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }

    /// The cap is checked before a chunk is appended, so a single chunk far larger
    /// than 64 KiB must be truncated *within* the chunk rather than buffered whole.
    /// The un-logged tail still has to reach the caller, so the body round-trips
    /// intact even though only a capped slice was logged.
    @Test("debug level caps mid-chunk when one chunk exceeds the log cap")
    internal func oversizedSingleChunkIsCappedButReplayedIntact() async throws {
      // One chunk, four times the cap, delivered as a stream of unknown length so
      // the middleware cannot shortcut on a known content length.
      #if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
        let chunk = Data((0..<262_144).map { UInt8($0 % 251) })
        let stream = AsyncThrowingStream<HTTPBody.ByteChunk, any Error> { continuation in
          continuation.yield(ArraySlice(chunk))
          continuation.finish()
        }
        let collected = try await Self.intercept(
          Self.debugMiddleware(), returning: HTTPBody(stream, length: .unknown)
        )
        #expect(collected == chunk)
      #else
        Issue.record("Omitted on Windows × Swift 6.2 (MistKitTests emit tip-over).")
      #endif
    }
  }
}
