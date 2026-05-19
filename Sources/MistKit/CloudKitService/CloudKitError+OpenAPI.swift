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
    guard let error = response.toCloudKitError() else {
      return nil
    }
    self = error
  }

  /// Build a `CloudKitError` from any CloudKit failure response.
  /// The body schema is identical across status codes — only the code
  /// disambiguates which CloudKit failure occurred, so the caller supplies it.
  ///
  /// Three server codes are surfaced as dedicated cases:
  /// - `QUOTA_EXCEEDED` → `.quotaExceeded(reason:, hint: nil)` — the catch
  ///   block in the calling operation may enrich `hint` from local context.
  /// - `BAD_REQUEST` → `.badRequest(reason:)`
  /// - `ATOMIC_ERROR` → `.atomicFailure(reason:)`
  ///
  /// Every other server code lands in `.httpErrorWithDetails`.
  internal init(_ response: Components.Responses.Failure, statusCode: Int) {
    switch response.body {
    case .json(let errorResponse):
      let code = errorResponse.serverErrorCode?.rawValue
      let reason = errorResponse.reason
      switch code {
      case "QUOTA_EXCEEDED":
        self = .quotaExceeded(reason: reason, hint: nil)
      case "BAD_REQUEST":
        self = .badRequest(reason: reason)
      case "ATOMIC_ERROR":
        self = .atomicFailure(reason: reason)
      default:
        self = .httpErrorWithDetails(
          statusCode: statusCode,
          serverErrorCode: code,
          reason: reason
        )
      }
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

  /// Returns a copy of this error with the given hint attached.
  ///
  /// If `self` is already `.quotaExceeded`, the existing reason is preserved
  /// and the hint is replaced. If `self` is a bare 413 (`.httpError(413)` or
  /// `.httpErrorWithDetails(413, …)`) — e.g., from the CDN asset-upload
  /// endpoint, which returns raw HTTP errors rather than CloudKit JSON —
  /// the error is upgraded to `.quotaExceeded` with the hint attached.
  /// Other cases are returned unchanged. `nil` hint is always a no-op.
  ///
  /// Used by operation catch blocks to enrich a server-returned quota error
  /// with information that can only be computed from the local request state
  /// (e.g., the actual encoded record size, the asset byte count).
  internal func addingQuotaHint(_ hint: QuotaHint?) -> CloudKitError {
    guard let hint else {
      return self
    }
    switch self {
    case .quotaExceeded(let reason, _):
      return .quotaExceeded(reason: reason, hint: hint)
    case .httpError(let statusCode) where statusCode == 413:
      return .quotaExceeded(reason: nil, hint: hint)
    case .httpErrorWithDetails(let statusCode, _, let reason) where statusCode == 413:
      return .quotaExceeded(reason: reason, hint: hint)
    default:
      return self
    }
  }
}
