//
//  StreamingTransport.swift
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
internal import OpenAPIRuntime

/// A transport whose response body can be read only once, with an unknown
/// length, like `URLSessionTransport`'s streaming bodies.
///
/// `RecordingTransport` answers with a `Data`-backed body that can be read any
/// number of times, which hides bugs where a body is read twice.
internal struct StreamingTransport: ClientTransport, Sendable {
  private let statusCode: Int
  private let headers: HTTPFields
  private let chunks: [Data]

  internal init(statusCode: Int, headers: HTTPFields = HTTPFields(), chunks: [Data]) {
    self.statusCode = statusCode
    self.headers = headers
    self.chunks = chunks
  }

  internal func send(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let chunks = self.chunks
    let stream = AsyncStream<ArraySlice<UInt8>> { continuation in
      for chunk in chunks {
        continuation.yield(ArraySlice(chunk))
      }
      continuation.finish()
    }
    return (
      HTTPResponse(status: .init(code: statusCode), headerFields: headers),
      HTTPBody(stream, length: .unknown, iterationBehavior: .single)
    )
  }
}
