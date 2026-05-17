//
//  CloudKitError+OpenAPI.swift
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

internal import Logging
internal import MistKitOpenAPI

extension CloudKitError {
  /// Generic failable initializer for any `CloudKitResponseType`.
  /// Returns `nil` when the response is `.ok`.
  internal init?<T: CloudKitResponseType>(_ response: T) {
    guard let error = response.toCloudKitError() else { return nil }
    self = error
  }

  /// Build a `CloudKitError` from any CloudKit failure response.
  /// The body schema is identical across status codes — only the code
  /// disambiguates which CloudKit failure occurred, so the caller supplies it.
  internal init(_ response: Components.Responses.Failure, statusCode: Int) {
    switch response.body {
    case .json(let errorResponse):
      self = .httpErrorWithDetails(
        statusCode: statusCode,
        serverErrorCode: errorResponse.serverErrorCode?.rawValue,
        reason: errorResponse.reason
      )
    }
  }

  /// Build an `.httpError` for an undocumented response and log the occurrence.
  /// The full response value is logged at `.debug` because it may echo server-side
  /// request data (e.g. emails passed to `lookupUsersByEmail`); the `.warning` line
  /// stays sanitized so it can ship to ops/log aggregators without leaking PII.
  internal static func undocumented(statusCode: Int, response: some Any) -> CloudKitError {
    let logger = Logger(subsystem: .api)
    logger.debug("Unhandled response (HTTP \(statusCode)): \(response)")
    logger.warning(
      "Unhandled \(type(of: response)) (HTTP \(statusCode)) - treating as generic HTTP error"
    )
    return .httpError(statusCode: statusCode)
  }
}
