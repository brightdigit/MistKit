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
  /// An HTTP failure whose CloudKit JSON body carried **no** `serverErrorCode`.
  ///
  /// Every documented `serverErrorCode` has its own case, and any code MistKit
  /// does not recognize becomes ``CloudKitError/unknownServerError(code:statusCode:reason:)``
  /// — so this case never carries a server code and consumers never have to
  /// string-match one.
  case httpErrorWithDetails(statusCode: Int, reason: String?)
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
  /// HTTP 403 / `ACCESS_DENIED`. The authenticated principal is not permitted
  /// to perform the operation on the target container, database, or record.
  case accessDenied(reason: String?)
  /// HTTP 401 / `AUTHENTICATION_FAILED`. The supplied credentials were
  /// rejected — expired web-auth token, bad signature, or unknown key ID.
  case authenticationFailed(reason: String?)
  /// HTTP 421 / `AUTHENTICATION_REQUIRED`. The request needs a user-attributed
  /// credential; the caller must complete the web-auth sign-in flow.
  case authenticationRequired(reason: String?)
  /// HTTP 409 / `CONFLICT`. The supplied `recordChangeTag` did not match the
  /// server's copy — the record changed since it was fetched.
  case conflict(reason: String?)
  /// HTTP 409 / `EXISTS`. A record or zone with the requested identifier
  /// already exists.
  case exists(reason: String?)
  /// HTTP 500 / `INTERNAL_ERROR`. CloudKit failed on its side.
  case internalServerError(reason: String?)
  /// HTTP 404 / `NOT_FOUND`. The requested record, record type, or resource
  /// does not exist.
  case notFound(reason: String?)
  /// HTTP 429 / `THROTTLED`. The caller is being rate limited; back off and
  /// retry.
  case throttled(reason: String?)
  /// HTTP 503 / `TRY_AGAIN_LATER`. CloudKit is temporarily unavailable.
  case tryAgainLater(reason: String?)
  /// HTTP 412 / `VALIDATING_REFERENCE_ERROR`. A reference field pointed at a
  /// record that failed validation — typically a missing target record.
  case validatingReferenceError(reason: String?)
  /// HTTP 404 / `ZONE_NOT_FOUND`. The named custom zone does not exist in the
  /// target database.
  case zoneNotFound(reason: String?)
  /// A `serverErrorCode` MistKit does not model — Apple added a code after this
  /// release. `code` is the raw wire string and `statusCode` the status that
  /// actually accompanied it.
  case unknownServerError(code: String, statusCode: Int, reason: String?)
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
  /// A per-zone entry in a `changes/database` / `changes/zone` response came
  /// back as a zone fetch error, surfaced by ``OperationResult/get()`` on a
  /// ``ZoneChangeResult``.
  case zoneOperationFailed(ZoneOperationFailure)
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
  /// `Asset.download(using:)` had no usable `downloadURL`.
  case missingAssetDownloadURL
  /// `Asset.download(using:)` requires `fileChecksum` and never returns bytes
  /// that have not been verified against it.
  case missingAssetChecksum
  /// Downloaded asset bytes did not match `Asset.fileChecksum` (SHA-256 of the
  /// plaintext, compared as base64 then as hex).
  case assetChecksumMismatch

  /// HTTP status code if this error originated from an HTTP response, otherwise nil.
  ///
  /// For the cases that model a CloudKit `serverErrorCode` this is the status
  /// Apple documents for that code, except for
  /// ``unknownServerError(code:statusCode:reason:)``, which reports the status
  /// actually observed on the wire.
  public var httpStatusCode: Int? {
    if let serverErrorDetail {
      return serverErrorDetail.statusCode
    }
    switch self {
    case .httpError(let statusCode),
      .httpErrorWithDetails(let statusCode, _),
      .httpErrorWithRawResponse(let statusCode, _):
      return statusCode
    default:
      return nil
    }
  }

  // `errorDescription` lives in `CloudKitError+ErrorDescription.swift`.
}
