//
//  CloudKitError.swift
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

public import Foundation

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

/// Represents errors that can occur when interacting with CloudKit Web Services
public enum CloudKitError: LocalizedError, Sendable {
  case httpError(statusCode: Int)
  /// Server-returned error for `serverErrorCode` values **other than**
  /// `QUOTA_EXCEEDED`, `BAD_REQUEST`, and `ATOMIC_ERROR` — those have their own
  /// dedicated cases (`.quotaExceeded`, `.badRequest`, `.atomicFailure`).
  case httpErrorWithDetails(statusCode: Int, serverErrorCode: String?, reason: String?)
  case httpErrorWithRawResponse(statusCode: Int, rawResponse: String)
  /// HTTP 413 / `QUOTA_EXCEEDED`. Same server code is used for storage-quota
  /// exhaustion and per-record / per-asset size limits; `hint` (when non-nil)
  /// disambiguates from local request context.
  case quotaExceeded(reason: String?, hint: QuotaHint?)
  /// HTTP 400 / `BAD_REQUEST`. The server's `reason` describes the specific
  /// malformed input.
  case badRequest(reason: String?)
  /// HTTP 400 / `ATOMIC_ERROR`. A `modifyRecords` call with `atomic: true`
  /// rolled back because at least one operation in the batch failed.
  case atomicFailure(reason: String?)
  case invalidResponse
  /// A multi-step convenience (e.g. `rereferenceAsset`) received a structurally
  /// valid CloudKit response that lacked data it needed to proceed. `reason`
  /// names exactly what was missing.
  case incompleteResponse(reason: String)
  /// A CloudKit response decoded at the transport layer but a specific value
  /// could not be mapped into a MistKit domain type — e.g. an unmappable field
  /// value, a record/zone/user missing a required identifier, or an unknown
  /// union case. Wraps the structured ``ConversionError`` naming exactly what
  /// failed (the field/zone/record and why).
  case conversionFailed(ConversionError)
  /// A per-record operation in a `modifyRecords`/`lookupRecords` batch came
  /// back as a `RecordOperationFailure`, surfaced by a single-record
  /// convenience (`createRecord`/`updateRecord`/`deleteRecord`).
  case recordOperationFailed(RecordOperationFailure)
  /// A per-subscription operation in a `modifySubscriptions` batch came back as
  /// a `SubscriptionOperationFailure`, surfaced by the single-subscription
  /// convenience (`createSubscription`).
  case subscriptionOperationFailed(SubscriptionOperationFailure)
  /// `createSubscription` failed with `INTERNAL_ERROR` and the exact reason
  /// string CloudKit returns when a *semantically-matching* subscription
  /// (same query + `firesOn`, regardless of `subscriptionID`) already
  /// exists. **This is MistKit's inference, not a guaranteed cause** — the
  /// underlying wire error is `INTERNAL_ERROR` with no formal "already
  /// exists" code, and the original ``SubscriptionOperationFailure`` is
  /// preserved so callers can inspect the raw signal.
  case subscriptionLikelyDuplicate(SubscriptionOperationFailure)
  case underlyingError(any Error)
  case decodingError(DecodingError)
  case networkError(URLError)
  case unsupportedOperationType(String)
  case paginationLimitExceeded(maxPages: Int, records: [RecordInfo])
  /// Auto-paginating zone-changes call hit its `maxPages` ceiling. The
  /// `zones` payload carries every zone collected before the cap was hit so
  /// callers can resume from the partial result.
  case zonePaginationLimitExceeded(maxPages: Int, zones: [ZoneInfo])
  case missingCredentials(
    database: Database,
    availability: CredentialAvailability = .notConfigured,
    reason: String
  )
  case invalidPrivateKey(path: String?, underlying: any Error)

  /// HTTP status code if this error originated from an HTTP response, otherwise nil.
  public var httpStatusCode: Int? {
    switch self {
    case .httpError(let statusCode),
      .httpErrorWithDetails(let statusCode, _, _),
      .httpErrorWithRawResponse(let statusCode, _):
      return statusCode
    case .quotaExceeded:
      return 413
    case .badRequest, .atomicFailure:
      return 400
    case .invalidResponse, .incompleteResponse, .conversionFailed, .recordOperationFailed,
      .subscriptionOperationFailed, .subscriptionLikelyDuplicate,
      .underlyingError, .decodingError, .networkError,
      .unsupportedOperationType, .paginationLimitExceeded,
      .zonePaginationLimitExceeded, .missingCredentials, .invalidPrivateKey:
      return nil
    }
  }

  // `errorDescription` lives in `CloudKitError+ErrorDescription.swift`.
}
