//
//  LoggingMiddlewareTests+StatusTests.swift
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
  // MARK: - HTTP Status Code Tests

  @Test(
    "LoggingMiddleware handles various HTTP status codes",
    arguments: [
      HTTPResponse.Status.ok,
      HTTPResponse.Status.created,
      HTTPResponse.Status.accepted,
      HTTPResponse.Status.noContent,
      HTTPResponse.Status.badRequest,
      HTTPResponse.Status.unauthorized,
      HTTPResponse.Status.forbidden,
      HTTPResponse.Status.notFound,
      HTTPResponse.Status.internalServerError,
    ]
  )
  internal func handlesVariousStatusCodes(status: HTTPResponse.Status) async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test"
    )
    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      let response = HTTPResponse(status: status)
      return (response, nil)
    }

    let (response, _) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(response.status == status)
  }

  @Test("LoggingMiddleware handles 421 Misdirected Request")
  internal func handles421Status() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test"
    )
    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      let response = HTTPResponse(status: .init(code: 421, reasonPhrase: "Misdirected Request"))
      return (response, nil)
    }

    let (response, _) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(response.status.code == 421)
  }

  // MARK: - Request Header Tests

  @Test("LoggingMiddleware handles requests with headers")
  internal func handlesRequestHeaders() async throws {
    let middleware = LoggingMiddleware()
    var request = HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/test"
    )
    request.headerFields[.authorization] = "Bearer token"
    request.headerFields[.contentType] = "application/json"

    let body: HTTPBody? = nil
    let baseURL = try #require(URL(string: "https://api.apple-cloudkit.com"))

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
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
}
