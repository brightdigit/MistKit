//
//  LoggingMiddlewareTests.swift
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

@Suite("LoggingMiddleware Tests")
struct LoggingMiddlewareTests {

  // MARK: - Basic Middleware Tests

  @Test("LoggingMiddleware intercepts and passes through requests")
  func interceptsAndPassesThrough() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/database/1/test/development/public/records/query")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    var nextCalled = false
    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      nextCalled = true
      let response = HTTPResponse(status: .ok)
      return (response, nil)
    }

    let (response, responseBody) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "test",
      next: next
    )

    #expect(nextCalled == true)
    #expect(response.status == .ok)
    #expect(responseBody == nil)
  }

  @Test("LoggingMiddleware handles POST requests")
  func handlesPostRequests() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .post, scheme: "https", authority: "api.apple-cloudkit.com", path: "/database/1/test/development/public/records/modify")
    let bodyData = Data("{\"records\":[]}".utf8)
    let body = HTTPBody(bodyData)
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      let response = HTTPResponse(status: .ok)
      return (response, nil)
    }

    let (response, _) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "modify",
      next: next
    )

    #expect(response.status == .ok)
  }

  @Test("LoggingMiddleware handles response bodies")
  func handlesResponseBodies() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/database/1/test/development/public/records/query")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    let responseBodyData = Data("{\"records\":[]}".utf8)
    let responseBody = HTTPBody(responseBodyData)

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      let response = HTTPResponse(status: .ok)
      return (response, responseBody)
    }

    let (response, returnedBody) = try await middleware.intercept(
      request,
      body: body,
      baseURL: baseURL,
      operationID: "query",
      next: next
    )

    #expect(response.status == .ok)

    #if DEBUG
    // In DEBUG builds, body should be recreated
    #expect(returnedBody != nil)
    #else
    // In RELEASE builds, body should pass through as-is
    #expect(returnedBody != nil)
    #endif
  }

  // MARK: - Error Handling Tests

  @Test("LoggingMiddleware propagates errors from next")
  func propagatesErrors() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    enum TestError: Error {
      case simulatedFailure
    }

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
      throw TestError.simulatedFailure
    }

    do {
      _ = try await middleware.intercept(
        request,
        body: body,
        baseURL: baseURL,
        operationID: "test",
        next: next
      )
      Issue.record("Expected error to be propagated")
    } catch {
      // Expected - error should propagate through middleware
      #expect(error is TestError)
    }
  }

  // MARK: - HTTP Status Code Tests

  @Test("LoggingMiddleware handles various HTTP status codes", arguments: [
    HTTPResponse.Status.ok,
    HTTPResponse.Status.created,
    HTTPResponse.Status.accepted,
    HTTPResponse.Status.noContent,
    HTTPResponse.Status.badRequest,
    HTTPResponse.Status.unauthorized,
    HTTPResponse.Status.forbidden,
    HTTPResponse.Status.notFound,
    HTTPResponse.Status.internalServerError
  ])
  func handlesVariousStatusCodes(status: HTTPResponse.Status) async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

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
  func handles421Status() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

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
  func handlesRequestHeaders() async throws {
    let middleware = LoggingMiddleware()
    var request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    request.headerFields[.authorization] = "Bearer token"
    request.headerFields[.contentType] = "application/json"

    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

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

  // MARK: - Query Parameter Tests

  @Test("LoggingMiddleware handles query parameters")
  func handlesQueryParameters() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test?key=value&foo=bar")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

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

  // MARK: - HTTP Method Tests

  @Test("LoggingMiddleware handles all HTTP methods", arguments: [
    HTTPRequest.Method.get,
    HTTPRequest.Method.post,
    HTTPRequest.Method.put,
    HTTPRequest.Method.delete,
    HTTPRequest.Method.patch,
    HTTPRequest.Method.head,
    HTTPRequest.Method.options
  ])
  func handlesAllHTTPMethods(method: HTTPRequest.Method) async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: method, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

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

  // MARK: - Large Response Body Tests

  @Test("LoggingMiddleware handles large response bodies")
  func handlesLargeResponseBodies() async throws {
    let middleware = LoggingMiddleware()
    let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test")
    let body: HTTPBody? = nil
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    // Create a large response body (100KB)
    let largeData = Data(repeating: 0x41, count: 100_000)
    let responseBody = HTTPBody(largeData)

    let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
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
  func handlesConcurrentRequests() async throws {
    let middleware = LoggingMiddleware()
    let baseURL = URL(string: "https://api.apple-cloudkit.com")!

    // Launch multiple concurrent requests
    try await withThrowingTaskGroup(of: HTTPResponse.Status.self) { group in
      for i in 1...5 {
        group.addTask {
          let request = HTTPRequest(method: .get, scheme: "https", authority: "api.apple-cloudkit.com", path: "/test/\(i)")
          let body: HTTPBody? = nil

          let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = { _, _, _ in
            let response = HTTPResponse(status: .ok)
            return (response, nil)
          }

          let (response, _) = try await middleware.intercept(
            request,
            body: body,
            baseURL: baseURL,
            operationID: "test\(i)",
            next: next
          )

          return response.status
        }
      }

      // Verify all requests completed successfully
      for try await status in group {
        #expect(status == .ok)
      }
    }
  }
}
