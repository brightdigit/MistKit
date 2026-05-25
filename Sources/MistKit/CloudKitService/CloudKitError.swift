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
internal import OpenAPIRuntime

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
    case .invalidResponse, .conversionFailed, .recordOperationFailed,
      .subscriptionOperationFailed, .underlyingError, .decodingError, .networkError,
      .unsupportedOperationType, .paginationLimitExceeded,
      .zonePaginationLimitExceeded, .missingCredentials, .invalidPrivateKey:
      return nil
    }
  }

  /// A localized message describing what error occurred
  public var errorDescription: String? {
    switch self {
    case .httpError(let statusCode):
      return "CloudKit API error: HTTP \(statusCode)"
    case .httpErrorWithDetails(let statusCode, let serverErrorCode, let reason):
      var message = "CloudKit API error: HTTP \(statusCode)"
      if let serverErrorCode = serverErrorCode {
        message += "\nServer Error Code: \(serverErrorCode)"
      }
      if let reason = reason {
        message += "\nReason: \(reason)"
      }
      return message
    case .httpErrorWithRawResponse(let statusCode, let rawResponse):
      return "CloudKit API error: HTTP \(statusCode)\nRaw Response: \(rawResponse)"
    case .invalidResponse:
      return "Invalid response from CloudKit"
    case .conversionFailed(let conversionError):
      return "Failed to convert CloudKit response into a MistKit type: "
        + (conversionError.errorDescription ?? "\(conversionError)")
    case .recordOperationFailed(let recordError):
      var message =
        "CloudKit record operation failed for '\(recordError.recordName)' "
        + "(\(recordError.serverErrorCode.rawValue))"
      if let reason = recordError.reason {
        message += "\nReason: \(reason)"
      }
      return message
    case .subscriptionOperationFailed(let subscriptionError):
      var message =
        "CloudKit subscription operation failed for '\(subscriptionError.subscriptionID)' "
        + "(\(subscriptionError.serverErrorCode.rawValue))"
      if let reason = subscriptionError.reason {
        message += "\nReason: \(reason)"
      }
      return message
    case .underlyingError(let error):
      return "CloudKit operation failed with underlying error: \(String(reflecting: error))"
    case .decodingError(let error):
      var message = "Failed to decode CloudKit response"
      switch error {
      case .keyNotFound(let key, let context):
        message += "\nMissing key: \(key.stringValue)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .typeMismatch(let type, let context):
        message += "\nType mismatch: expected \(type)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .valueNotFound(let type, let context):
        message += "\nValue not found: expected \(type)"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      case .dataCorrupted(let context):
        message += "\nData corrupted"
        message += "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
        if let underlyingError = context.underlyingError {
          message += "\nUnderlying error: \(underlyingError.localizedDescription)"
        }
      @unknown default:
        message += "\nUnknown decoding error: \(error.localizedDescription)"
      }
      return message
    case .networkError(let error):
      var message = "Network error occurred"
      message += "\nError code: \(error.code.rawValue)"
      if let url = error.failureURLString {
        message += "\nFailed URL: \(url)"
      }
      message += "\nDescription: \(error.localizedDescription)"
      return message
    case .unsupportedOperationType(let type):
      return "Unsupported record operation type: \(type)"
    case .paginationLimitExceeded(let maxPages, let records):
      return
        "CloudKit query exceeded pagination limit of \(maxPages) pages "
        + "(collected \(records.count) records)"
    case .zonePaginationLimitExceeded(let maxPages, let zones):
      return
        "CloudKit zone-changes exceeded pagination limit of \(maxPages) pages "
        + "(collected \(zones.count) zones)"
    case .missingCredentials(let database, let availability, let reason):
      let availabilityLabel: String
      switch availability {
      case .notConfigured:
        availabilityLabel = "not configured"
      case .preferenceRequired:
        availabilityLabel = "required by preference but not configured"
      }
      return
        "Missing credentials for database '\(database.pathSegment)' "
        + "(\(availabilityLabel)): \(reason)"
    case .invalidPrivateKey(let path, let underlying):
      let location = path.map { "from '\($0)'" } ?? "from inline material"
      return
        "Failed to load CloudKit private key \(location): \(underlying.localizedDescription)"
    case .quotaExceeded(let reason, let hint):
      var message = "CloudKit quota exceeded (HTTP 413 / QUOTA_EXCEEDED)"
      if let reason {
        message += "\nReason: \(reason)"
      }
      if let hint {
        message += "\nHint: \(hint.description)"
      }
      return message
    case .badRequest(let reason):
      var message = "CloudKit bad request (HTTP 400 / BAD_REQUEST)"
      if let reason {
        message += "\nReason: \(reason)"
      }
      return message
    case .atomicFailure(let reason):
      var message = "CloudKit atomic batch failure (HTTP 400 / ATOMIC_ERROR)"
      if let reason {
        message += "\nReason: \(reason)"
      }
      return message
    }
  }
}
