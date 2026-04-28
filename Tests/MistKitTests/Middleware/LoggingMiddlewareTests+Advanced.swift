//
//  LoggingMiddlewareTests+Advanced.swift
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
  // MARK: - Query Parameter Tests

  @Test("LoggingMiddleware handles query parameters")
  internal func handlesQueryParameters() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test?key=value&foo=bar"
    )
    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let next:
      (HTTPRequest, HTTPBody?, URL) async throws
        -> (HTTPResponse, HTTPBody?) = { _, _, _ in
          let response = HTTPResponse(status: .ok)
          return (response, nil)
        }

    let (response, _) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(response.status == .ok)
  }

  // MARK: - HTTP Method Tests

  @Test(
    "LoggingMiddleware handles all HTTP methods",
    arguments: [
      HTTPRequest.Method.get,
      HTTPRequest.Method.post,
      HTTPRequest.Method.put,
      HTTPRequest.Method.delete,
      HTTPRequest.Method.patch,
      HTTPRequest.Method.head,
      HTTPRequest.Method.options,
    ]
  )
  internal func handlesAllHTTPMethods(
    method: HTTPRequest.Method
  ) async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(
      method: method,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test"
    )
    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let next:
      (HTTPRequest, HTTPBody?, URL) async throws
        -> (HTTPResponse, HTTPBody?) = { _, _, _ in
          let response = HTTPResponse(status: .ok)
          return (response, nil)
        }

    let (response, _) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(response.status == .ok)
  }

  // MARK: - Large Response Body Tests

  @Test("LoggingMiddleware handles large response bodies")
  internal func handlesLargeResponseBodies() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test"
    )
    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let largeData = Data(repeating: 0x41, count: 100_000)
    let responseBody = HTTPBody(largeData)

    let next:
      (HTTPRequest, HTTPBody?, URL) async throws
        -> (HTTPResponse, HTTPBody?) = { _, _, _ in
          let response = HTTPResponse(status: .ok)
          return (response, responseBody)
        }

    let (response, returnedBody) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(response.status == .ok)
    #expect(returnedBody != nil)
  }

  // MARK: - Concurrent Request Tests

  @Test("LoggingMiddleware handles concurrent requests")
  internal func handlesConcurrentRequests() async throws {
    let middleware = LoggingMiddleware()
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    try await withThrowingTaskGroup(of: HTTPResponse.Status.self) { group in
      for requestIndex in 1...5 {
        group.addTask {
          let request = HTTPRequest(
            method: .get,
            scheme: "https",
            authority: "api.apple-cloudkit.com",
            path: "/test/\(requestIndex)"
          )
          let body: HTTPBody? = nil

          let next:
            (HTTPRequest, HTTPBody?, URL) async throws
              -> (HTTPResponse, HTTPBody?) = { _, _, _ in
                let response = HTTPResponse(status: .ok)
                return (response, nil)
              }

          let (response, _) = try await middleware.intercept(
            request,
            body: body,
            baseURL: baseURL,
            operationID: "test\(requestIndex)",
            next: next
          )

          return response.status
        }
      }

      for try await status in group {
        #expect(status == .ok)
      }
    }
  }
}
