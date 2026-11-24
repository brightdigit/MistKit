//
//  ManagementErrorBodyMiddleware.swift
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

/// Buffers the body of a non-success Management API response so it can be
/// read twice.
///
/// The generated client reads an error body once, to decode a `RequestError`.
/// When that fails (the body isn't JSON, or is missing a required key), the
/// `ClientError` it throws carries the same body, which a streaming transport
/// can't replay. Buffering it here keeps it readable for
/// ``CloudKitManagementError/httpError(statusCode:body:)``. A body over
/// ``maxErrorBodyBytes`` is dropped.
internal struct ManagementErrorBodyMiddleware: ClientMiddleware {
  /// The largest error body kept. Error bodies are short JSON or text.
  internal static let maxErrorBodyBytes = 1_024 * 1_024

  /// Replaces a non-success response's body with a buffered copy.
  internal func intercept(
    _ request: HTTPRequest,
    body: HTTPBody?,
    baseURL: URL,
    operationID: String,
    next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
  ) async throws -> (HTTPResponse, HTTPBody?) {
    let (response, responseBody) = try await next(request, body, baseURL)
    guard response.status.kind != .successful, let responseBody else {
      return (response, responseBody)
    }
    // An error body over the cap, or one that fails mid-read, is dropped on
    // purpose: the status code still reaches CloudKitManagementError, and a
    // RequestError is a few hundred bytes, so losing a huge body loses nothing
    // a caller could act on.
    guard
      let data = try? await Data(collecting: responseBody, upTo: Self.maxErrorBodyBytes)
    else {
      return (response, nil)
    }
    return (response, HTTPBody(data))
  }
}
