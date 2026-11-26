//
//  ManagementTokenMiddlewareTests.swift
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
internal import Testing

@testable import MistKit

@Suite("Management token middleware")
internal struct ManagementTokenMiddlewareTests {
  @Test("Adds the token header and leaves the rest of the request alone")
  internal func addsHeader() async throws {
    var headers = HTTPFields()
    headers[.accept] = "text/plain"
    let request = HTTPRequest(
      method: .get,
      scheme: nil,
      authority: nil,
      path: "/v1/x",
      headerFields: headers
    )
    let baseURL = try #require(URL(string: "https://api.icloud.apple.com"))
    let middleware = ManagementTokenMiddleware(managementToken: ManagementToken("tok"))
    nonisolated(unsafe) var forwarded: (HTTPRequest, URL)?
    _ = try await middleware.intercept(
      request,
      body: nil,
      baseURL: baseURL,
      operationID: "exportSchema"
    ) { request, _, url in
      forwarded = (request, url)
      return (HTTPResponse(status: .ok), nil)
    }
    let (sent, sentURL) = try #require(forwarded)
    #expect(sent.headerFields[.cloudKitManagementToken] == "tok")
    #expect(sent.headerFields[.accept] == "text/plain")
    #expect(sent.method == .get)
    #expect(sent.path == "/v1/x")
    #expect(sentURL == baseURL)
  }
}
