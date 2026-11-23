//
//  CloudKitError+Retry.swift
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
  /// The `reason` CloudKit sent with the failure, or `nil` when the error
  /// didn't come from a CloudKit failure body or the body had none.
  ///
  /// Covers every case that models a `serverErrorCode`, a coded failure body
  /// without a code (``CloudKitError/httpErrorWithDetails(statusCode:reason:)``)
  /// and the per-item failures surfaced by single-item conveniences. Use it for
  /// display and logs; switch on the cases for control flow.
  ///
  /// This and the other properties here read through
  /// ``CloudKitError/modifyIncomplete(completed:unsent:underlying:)`` to its
  /// `underlying` error.
  public var reason: String? {
    if case .modifyIncomplete(_, _, let underlying) = self {
      return underlying.reason
    }
    if let serverErrorDetail {
      return serverErrorDetail.reason
    }
    switch self {
    case .httpErrorWithDetails(_, let reason):
      return reason
    case .recordOperationFailed(let failure):
      return failure.reason
    case .subscriptionOperationFailed(let failure),
      .subscriptionLikelyDuplicate(let failure):
      return failure.reason
    default:
      return nil
    }
  }

  /// The number of seconds CloudKit asked the caller to wait before trying
  /// again, or `nil` when it sent none.
  ///
  /// Read from a request-level `THROTTLED` / `TRY_AGAIN_LATER` failure body or
  /// from the per-record failure a single-record convenience surfaced.
  public var retryAfter: Int? {
    if case .modifyIncomplete(_, _, let underlying) = self {
      return underlying.retryAfter
    }
    switch self {
    case .throttled(_, let retryAfter), .tryAgainLater(_, let retryAfter):
      return retryAfter
    case .recordOperationFailed(let failure):
      return failure.retryAfter
    case .subscriptionOperationFailed(let failure):
      return failure.retryAfter
    default:
      return nil
    }
  }

  /// The sign-in page CloudKit sent with an `AUTHENTICATION_REQUIRED`
  /// failure, or `nil` when it sent none.
  ///
  /// A request signed with only an API token gets this URL back; opening it
  /// starts the web sign-in flow that yields a web-auth token.
  public var redirectURL: String? {
    if case .modifyIncomplete(_, _, let underlying) = self {
      return underlying.redirectURL
    }
    switch self {
    case .authenticationRequired(_, let redirectURL):
      return redirectURL
    case .recordOperationFailed(let failure):
      return failure.redirectURL
    case .subscriptionOperationFailed(let failure):
      return failure.redirectURL
    default:
      return nil
    }
  }

  /// Whether CloudKit said the same request may succeed if sent again later:
  /// `THROTTLED` and `TRY_AGAIN_LATER`, at the request level or on the
  /// per-record failure a single-record convenience surfaced.
  ///
  /// MistKit never retries on its own. Callers that do should wait
  /// ``CloudKitError/retryAfter`` seconds when it's set and back off otherwise.
  /// Network failures aren't classed as retryable: whether to resend after
  /// losing the connection is the caller's decision.
  public var isRetryable: Bool {
    if case .modifyIncomplete(_, _, let underlying) = self {
      return underlying.isRetryable
    }
    switch self {
    case .throttled, .tryAgainLater:
      return true
    case .recordOperationFailed(let failure):
      return failure.serverErrorCode.isRetryable
    case .subscriptionOperationFailed(let failure):
      return failure.serverErrorCode.isRetryable
    default:
      return false
    }
  }
}

extension CloudKitServerErrorCode {
  /// Whether this code says the request may succeed later: ``throttled`` and
  /// ``tryAgainLater``.
  public var isRetryable: Bool {
    switch self {
    case .throttled, .tryAgainLater:
      return true
    default:
      return false
    }
  }
}
