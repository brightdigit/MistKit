//
//  CloudKitError+ServerErrorCode.swift
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

extension CloudKitError {
  /// The raw CloudKit `serverErrorCode` this error carries, or `nil` when the
  /// error did not originate from a coded CloudKit failure.
  ///
  /// Exposed for logging and diagnostics only. Pattern-match the dedicated
  /// cases — ``CloudKitError/notFound(reason:)``, ``CloudKitError/throttled(reason:)``
  /// and friends — for control flow; the string is not a stable contract.
  public var serverErrorCode: String? {
    serverErrorDetail?.code
  }

  /// Code, documented HTTP status, summary, and reason for every case that
  /// models a CloudKit `serverErrorCode`; `nil` for all other cases.
  ///
  /// The switch is deliberately exhaustive: adding a case to ``CloudKitError``
  /// stops compiling here until the new case is classified.
  // swiftlint:disable:next cyclomatic_complexity function_body_length
  internal var serverErrorDetail: ServerErrorCodeDetail? {
    switch self {
    case .accessDenied(let reason):
      return Self.detail("ACCESS_DENIED", 403, "access denied", reason)
    case .atomicFailure(let reason):
      return Self.detail("ATOMIC_ERROR", 400, "atomic batch failure", reason)
    case .authenticationFailed(let reason):
      return Self.detail("AUTHENTICATION_FAILED", 401, "authentication failed", reason)
    case .authenticationRequired(let reason):
      return Self.detail("AUTHENTICATION_REQUIRED", 421, "authentication required", reason)
    case .badRequest(let reason):
      return Self.detail("BAD_REQUEST", 400, "bad request", reason)
    case .conflict(let reason):
      return Self.detail("CONFLICT", 409, "conflict", reason)
    case .exists(let reason):
      return Self.detail("EXISTS", 409, "already exists", reason)
    case .internalServerError(let reason):
      return Self.detail("INTERNAL_ERROR", 500, "internal server error", reason)
    case .notFound(let reason):
      return Self.detail("NOT_FOUND", 404, "not found", reason)
    case .quotaExceeded(let reason, _):
      return Self.detail("QUOTA_EXCEEDED", 413, "quota exceeded", reason)
    case .throttled(let reason):
      return Self.detail("THROTTLED", 429, "throttled", reason)
    case .tryAgainLater(let reason):
      return Self.detail("TRY_AGAIN_LATER", 503, "try again later", reason)
    case .validatingReferenceError(let reason):
      return Self.detail("VALIDATING_REFERENCE_ERROR", 412, "reference validation error", reason)
    case .zoneNotFound(let reason):
      return Self.detail("ZONE_NOT_FOUND", 404, "zone not found", reason)
    case .unknownServerError(let code, let statusCode, let reason):
      return Self.detail(code, statusCode, "unrecognized server error", reason)
    case .httpError, .httpErrorWithDetails, .httpErrorWithRawResponse, .invalidResponse,
      .incompleteResponse, .conversionFailed, .recordOperationFailed,
      .subscriptionOperationFailed, .subscriptionLikelyDuplicate, .underlyingError,
      .decodingError, .networkError, .unsupportedOperationType, .paginationLimitExceeded,
      .zonePaginationLimitExceeded, .missingCredentials, .invalidPrivateKey:
      return nil
    }
  }

  /// Maps a CloudKit failure body onto the case that models its
  /// `serverErrorCode`.
  ///
  /// - A `nil` code (a failure body that carried no code) becomes
  ///   ``CloudKitError/httpErrorWithDetails(statusCode:reason:)``, preserving
  ///   the server `reason`.
  /// - Each of the fourteen codes documented in `openapi.yaml` becomes its own
  ///   dedicated case.
  /// - Anything else becomes
  ///   ``CloudKitError/unknownServerError(code:statusCode:reason:)`` so a code
  ///   Apple adds after this release still reaches the caller intact.
  ///
  /// - Parameters:
  ///   - code: The raw `serverErrorCode` string from the failure body.
  ///   - statusCode: The HTTP status the failure arrived with.
  ///   - reason: The server-supplied `reason`, when present.
  // swiftlint:disable:next cyclomatic_complexity
  internal init(serverErrorCode code: String?, statusCode: Int, reason: String?) {
    guard let code else {
      self = .httpErrorWithDetails(statusCode: statusCode, reason: reason)
      return
    }
    switch code {
    case "ACCESS_DENIED":
      self = .accessDenied(reason: reason)
    case "ATOMIC_ERROR":
      self = .atomicFailure(reason: reason)
    case "AUTHENTICATION_FAILED":
      self = .authenticationFailed(reason: reason)
    case "AUTHENTICATION_REQUIRED":
      self = .authenticationRequired(reason: reason)
    case "BAD_REQUEST":
      self = .badRequest(reason: reason)
    case "CONFLICT":
      self = .conflict(reason: reason)
    case "EXISTS":
      self = .exists(reason: reason)
    case "INTERNAL_ERROR":
      self = .internalServerError(reason: reason)
    case "NOT_FOUND":
      self = .notFound(reason: reason)
    case "QUOTA_EXCEEDED":
      // `hint` is enriched later by the calling operation's catch block, which
      // is the only place that can see the local request state.
      self = .quotaExceeded(reason: reason, hint: nil)
    case "THROTTLED":
      self = .throttled(reason: reason)
    case "TRY_AGAIN_LATER":
      self = .tryAgainLater(reason: reason)
    case "VALIDATING_REFERENCE_ERROR":
      self = .validatingReferenceError(reason: reason)
    case "ZONE_NOT_FOUND":
      self = .zoneNotFound(reason: reason)
    default:
      self = .unknownServerError(code: code, statusCode: statusCode, reason: reason)
    }
  }

  private static func detail(
    _ code: String,
    _ statusCode: Int,
    _ summary: String,
    _ reason: String?
  ) -> ServerErrorCodeDetail {
    ServerErrorCodeDetail(
      code: code, statusCode: statusCode, summary: summary, reason: reason
    )
  }
}
