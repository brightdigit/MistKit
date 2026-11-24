//
//  CloudKitManagementServiceTests+Response.swift
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
internal import Testing

@testable import MistKit

extension CloudKitManagementServiceTests {
  @Suite("Success responses")
  internal struct Response {
    private static func textHeaders() -> HTTPFields {
      var headers = HTTPFields()
      headers[.contentType] = "text/plain"
      return headers
    }

    @Test("An empty export is empty text, and isn't a schema")
    internal func emptyBody() async throws {
      let (service, _) = makeService(response: RecordedManagementFixtures.textResponse(""))
      #expect(try await service.exportSchemaText(environment: .development).isEmpty)
      await #expect {
        _ = try await service.exportSchema(environment: .development)
      } throws: { error in
        guard case .invalidSchema(_, let text) = error as? CloudKitManagementError else {
          return false
        }
        return text.isEmpty
      }
    }

    @Test("A body that isn't UTF-8 throws invalidResponse")
    internal func notUTF8() async throws {
      let (service, _) = makeService(
        response: ResponseConfig(
          statusCode: 200,
          headers: Self.textHeaders(),
          body: Data([0xFF, 0xFE, 0xFD])
        )
      )
      let error = await exportTextError(service)
      guard case .invalidResponse = error as? CloudKitManagementError else {
        Issue.record("Expected invalidResponse, got \(String(describing: error))")
        return
      }
    }

    @Test("A streamed body is read once, in chunks")
    internal func streamedBody() async throws {
      let service = makeService(
        transport: StreamingTransport(
          statusCode: 200,
          headers: Self.textHeaders(),
          chunks: [Data("DEFINE ".utf8), Data("SCHEMA".utf8)]
        )
      )
      #expect(try await service.exportSchemaText(environment: .development) == "DEFINE SCHEMA")
    }

    @Test(
      "A body over 32 MiB with a known length throws invalidResponse",
      .disabled(if: Platform.isWasm, "WASM's linear memory can't hold a 32 MiB body")
    )
    internal func oversizedKnownLength() async throws {
      let (service, _) = makeService(
        response: ResponseConfig(
          statusCode: 200,
          headers: Self.textHeaders(),
          body: Data(count: CloudKitManagementService.maxResponseBytes + 1)
        )
      )
      let error = await exportTextError(service)
      guard case .invalidResponse(let reason) = error as? CloudKitManagementError else {
        Issue.record("Expected invalidResponse, got \(String(describing: error))")
        return
      }
      #expect(reason.contains("exceeded"))
    }

    @Test(
      "A streamed body that grows past 32 MiB throws invalidResponse",
      .disabled(if: Platform.isWasm, "WASM's linear memory can't hold a 32 MiB body")
    )
    internal func oversizedStream() async throws {
      let megabyte = Data(count: 1_024 * 1_024)
      let chunkCount = CloudKitManagementService.maxResponseBytes / megabyte.count + 1
      let service = makeService(
        transport: StreamingTransport(
          statusCode: 200,
          headers: Self.textHeaders(),
          chunks: Array(repeating: megabyte, count: chunkCount)
        )
      )
      let error = await exportTextError(service)
      guard case .invalidResponse(let reason) = error as? CloudKitManagementError else {
        Issue.record("Expected invalidResponse, got \(String(describing: error))")
        return
      }
      #expect(reason.contains("exceeded"))
    }

    @Test("A 200 with an undocumented content type throws invalidResponse")
    internal func unexpectedContentType() async throws {
      var headers = HTTPFields()
      headers[.contentType] = "text/html"
      let (service, _) = makeService(
        response: ResponseConfig(statusCode: 200, headers: headers, body: Data("<html/>".utf8))
      )
      let error = await exportTextError(service)
      guard case .invalidResponse = error as? CloudKitManagementError else {
        Issue.record("Expected invalidResponse, got \(String(describing: error))")
        return
      }
    }
  }
}
