//
//  ManagementErrorBodyMiddlewareTests.swift
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

@Suite("Management error body middleware")
internal struct ManagementErrorBodyMiddlewareTests {
  private static func singleUseBody(_ text: String) -> HTTPBody {
    let stream = AsyncStream<ArraySlice<UInt8>> { continuation in
      continuation.yield(ArraySlice(Data(text.utf8)))
      continuation.finish()
    }
    return HTTPBody(stream, length: .unknown, iterationBehavior: .single)
  }

  private static func intercept(
    status: HTTPResponse.Status,
    body: HTTPBody?
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let request = HTTPRequest(method: .get, scheme: nil, authority: nil, path: "/")
    let baseURL = try #require(URL(string: "https://api.icloud.apple.com"))
    return try await ManagementErrorBodyMiddleware().intercept(
      request,
      body: nil,
      baseURL: baseURL,
      operationID: "exportSchema"
    ) { _, _, _ in
      (HTTPResponse(status: status), body)
    }
  }

  @Test("Buffers an error body so it can be read twice")
  internal func buffersErrorBody() async throws {
    let (_, body) = try await Self.intercept(
      status: .badGateway,
      body: Self.singleUseBody("Bad Gateway")
    )
    let buffered = try #require(body)
    #expect(buffered.iterationBehavior == .multiple)
    let first = try await Data(collecting: buffered, upTo: 1_024)
    let second = try await Data(collecting: buffered, upTo: 1_024)
    #expect(String(decoding: first, as: UTF8.self) == "Bad Gateway")
    #expect(second == first)
  }

  @Test("Passes a success body through untouched")
  internal func passesSuccessBody() async throws {
    let original = Self.singleUseBody("DEFINE SCHEMA")
    let (_, body) = try await Self.intercept(status: .ok, body: original)
    let passed = try #require(body)
    #expect(passed.iterationBehavior == .single)
    #expect(passed === original)
  }

  @Test("Drops an error body over the limit")
  internal func dropsOversizedErrorBody() async throws {
    let big = String(repeating: "x", count: ManagementErrorBodyMiddleware.maxErrorBodyBytes + 1)
    let (response, body) = try await Self.intercept(
      status: .internalServerError,
      body: Self.singleUseBody(big)
    )
    #expect(response.status == .internalServerError)
    #expect(body == nil)
  }
}
