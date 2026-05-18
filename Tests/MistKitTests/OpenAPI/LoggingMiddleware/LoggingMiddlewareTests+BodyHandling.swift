//
//  LoggingMiddlewareTests+BodyHandling.swift
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

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension LoggingMiddlewareTests {
  @Suite("Body Handling")
  internal struct BodyHandling {
    @Test("preserves JSON response body")
    internal func preservesJSONResponseBody() async throws {
      let middleware = LoggingMiddleware()
      let request = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/test"
      )
      let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))
      let jsonData = Data(#"{"foo":"bar"}"#.utf8)
      let responseBody = HTTPBody(jsonData)

      let next:
        (HTTPRequest, HTTPBody?, URL) async throws
          -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            var response = HTTPResponse(status: .ok)
            response.headerFields[.contentType] = "application/json"
            return (response, responseBody)
          }

      let (_, returnedBody) = try await middleware.intercept(
        request,
        body: nil,
        baseURL: baseURL,
        operationID: "test",
        next: next
      )

      let collected = try await Data(collecting: try #require(returnedBody), upTo: .max)
      #expect(collected == jsonData)
    }

    @Test("preserves non-JSON response body")
    internal func preservesNonJSONResponseBody() async throws {
      let middleware = LoggingMiddleware()
      let request = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/asset"
      )
      let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))
      let binaryData = Data(repeating: 0xAB, count: 200_000)
      let responseBody = HTTPBody(binaryData)

      let next:
        (HTTPRequest, HTTPBody?, URL) async throws
          -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            var response = HTTPResponse(status: .ok)
            response.headerFields[.contentType] = "application/octet-stream"
            return (response, responseBody)
          }

      let (_, returnedBody) = try await middleware.intercept(
        request,
        body: nil,
        baseURL: baseURL,
        operationID: "test",
        next: next
      )

      let collected = try await Data(collecting: try #require(returnedBody), upTo: .max)
      #expect(collected == binaryData)
    }
  }
}
