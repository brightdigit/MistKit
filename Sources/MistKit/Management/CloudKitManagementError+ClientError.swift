//
//  CloudKitManagementError+ClientError.swift
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
internal import OpenAPIRuntime

extension CloudKitManagementError {
  /// Turns a generated client's `ClientError` into the error callers see.
  ///
  /// A `ClientError` is never rethrown: its description includes the request,
  /// whose headers carry the management token.
  /// - No response (the transport failed): the transport's own error,
  ///   unchanged.
  /// - A non-success response the client couldn't decode as a `RequestError`:
  ///   ``httpError(statusCode:body:)`` with the buffered body (see
  ///   `ManagementErrorBodyMiddleware`), or ``requestFailed(_:)`` if the body
  ///   is a `RequestError` after all.
  /// - A success response it couldn't read: ``invalidResponse(reason:)``.
  internal static func translating(_ error: ClientError) async -> any Error {
    guard let response = error.response else {
      return error.underlyingError
    }
    guard response.status.kind != .successful else {
      return CloudKitManagementError.invalidResponse(reason: error.causeDescription)
    }
    var body = Data()
    if let responseBody = error.responseBody {
      body =
        (try? await Data(
          collecting: responseBody,
          upTo: ManagementErrorBodyMiddleware.maxErrorBodyBytes
        )) ?? Data()
    }
    return CloudKitManagementError(statusCode: response.status.code, body: body)
  }
}
