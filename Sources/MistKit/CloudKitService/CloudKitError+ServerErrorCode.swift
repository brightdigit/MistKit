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
  /// stops compiling here until the new case is classified. Wire strings and
  /// status numbers come from ``CloudKitServerErrorCode``'s catalog — never
  /// inlined here.
  // swiftlint:disable:next cyclomatic_complexity
  internal var serverErrorDetail: ServerErrorCodeDetail? {
    switch self {
    case .accessDenied(let reason):
      return ServerErrorCodeDetail(code: .accessDenied, reason: reason)
    case .atomicFailure(let reason):
      return ServerErrorCodeDetail(code: .atomicError, reason: reason)
    case .authenticationFailed(let reason):
      return ServerErrorCodeDetail(code: .authenticationFailed, reason: reason)
    case .authenticationRequired(let reason):
      return ServerErrorCodeDetail(code: .authenticationRequired, reason: reason)
    case .badRequest(let reason):
      return ServerErrorCodeDetail(code: .badRequest, reason: reason)
    case .conflict(let reason):
      return ServerErrorCodeDetail(code: .conflict, reason: reason)
    case .exists(let reason):
      return ServerErrorCodeDetail(code: .exists, reason: reason)
    case .internalServerError(let reason):
      return ServerErrorCodeDetail(code: .internalError, reason: reason)
    case .notFound(let reason):
      return ServerErrorCodeDetail(code: .notFound, reason: reason)
    case .quotaExceeded(let reason, _):
      return ServerErrorCodeDetail(code: .quotaExceeded, reason: reason)
    case .throttled(let reason):
      return ServerErrorCodeDetail(code: .throttled, reason: reason)
    case .tryAgainLater(let reason):
      return ServerErrorCodeDetail(code: .tryAgainLater, reason: reason)
    case .validatingReferenceError(let reason):
      return ServerErrorCodeDetail(code: .validatingReferenceError, reason: reason)
    case .zoneNotFound(let reason):
      return ServerErrorCodeDetail(code: .zoneNotFound, reason: reason)
    case .unknownServerError(let code, let statusCode, let reason):
      return ServerErrorCodeDetail(
        code: code,
        statusCode: statusCode,
        summary: ServerErrorCodeDetail.unrecognizedSummary,
        reason: reason
      )
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
  ///   dedicated case, looked up via ``CloudKitServerErrorCode``'s dictionary.
  /// - Anything else becomes
  ///   ``CloudKitError/unknownServerError(code:statusCode:reason:)`` so a code
  ///   Apple adds after this release still reaches the caller intact.
  ///
  /// - Parameters:
  ///   - code: The raw `serverErrorCode` string from the failure body.
  ///   - statusCode: The HTTP status the failure arrived with.
  ///   - reason: The server-supplied `reason`, when present.
  internal init(serverErrorCode code: String?, statusCode: Int, reason: String?) {
    guard let code else {
      self = .httpErrorWithDetails(statusCode: statusCode, reason: reason)
      return
    }
    // Dictionary lookup in `CloudKitServerErrorCode.init(rawValue:)` — no
    // string switch here. Map the typed enum onto the dedicated case.
    self = Self.make(
      from: CloudKitServerErrorCode(rawValue: code),
      statusCode: statusCode,
      reason: reason
    )
  }

  /// Builds the dedicated case for a typed ``CloudKitServerErrorCode``.
  ///
  /// `hint` for ``CloudKitError/quotaExceeded(reason:hint:)`` is enriched later
  /// by the calling operation's catch block, which is the only place that can
  /// see the local request state.
  // swiftlint:disable:next cyclomatic_complexity
  private static func make(
    from code: CloudKitServerErrorCode,
    statusCode: Int,
    reason: String?
  ) -> CloudKitError {
    switch code {
    case .accessDenied:
      return .accessDenied(reason: reason)
    case .atomicError:
      return .atomicFailure(reason: reason)
    case .authenticationFailed:
      return .authenticationFailed(reason: reason)
    case .authenticationRequired:
      return .authenticationRequired(reason: reason)
    case .badRequest:
      return .badRequest(reason: reason)
    case .conflict:
      return .conflict(reason: reason)
    case .exists:
      return .exists(reason: reason)
    case .internalError:
      return .internalServerError(reason: reason)
    case .notFound:
      return .notFound(reason: reason)
    case .quotaExceeded:
      return .quotaExceeded(reason: reason, hint: nil)
    case .throttled:
      return .throttled(reason: reason)
    case .tryAgainLater:
      return .tryAgainLater(reason: reason)
    case .validatingReferenceError:
      return .validatingReferenceError(reason: reason)
    case .zoneNotFound:
      return .zoneNotFound(reason: reason)
    case .unknown(let raw):
      return .unknownServerError(code: raw, statusCode: statusCode, reason: reason)
    }
  }
}
