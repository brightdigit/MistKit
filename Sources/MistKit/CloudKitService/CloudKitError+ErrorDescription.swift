//
//  CloudKitError+ErrorDescription.swift
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

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

extension CloudKitError {
  /// A localized message describing what error occurred
  public var errorDescription: String? {
    switch self {
    case .httpError(let statusCode):
      return "CloudKit API error: HTTP \(statusCode)"
    case .httpErrorWithDetails(let statusCode, let reason):
      return Self.simpleReasonDescription(
        prefix: "CloudKit API error: HTTP \(statusCode)", reason: reason
      )
    case .httpErrorWithRawResponse(let statusCode, let rawResponse):
      return "CloudKit API error: HTTP \(statusCode)\nRaw Response: \(rawResponse)"
    case .invalidResponse:
      return "Invalid response from CloudKit"
    case .incompleteResponse(let reason):
      return Self.simpleReasonDescription(prefix: "Incomplete CloudKit response", reason: reason)
    case .conversionFailed(let conversionError):
      return "Failed to convert CloudKit response into a MistKit type: "
        + (conversionError.errorDescription ?? "\(conversionError)")
    case .recordOperationFailed(let recordError):
      return Self.recordOperationDescription(recordError)
    case .zoneOperationFailed(let zoneError):
      return Self.zoneOperationDescription(zoneError)
    case .subscriptionOperationFailed(let subscriptionError):
      return Self.subscriptionOperationDescription(subscriptionError)
    case .subscriptionLikelyDuplicate(let subscriptionError):
      return Self.subscriptionLikelyDuplicateDescription(subscriptionError)
    case .underlyingError(let error):
      return "CloudKit operation failed with underlying error: \(String(reflecting: error))"
    case .decodingError(let error):
      return Self.decodingErrorDescription(error)
    case .networkError(let error):
      return Self.networkErrorDescription(error)
    case .unsupportedOperationType(let type):
      return "Unsupported record operation type: \(type)"
    case .paginationLimitExceeded(let maxPages, let records):
      return
        "CloudKit query exceeded pagination limit of \(maxPages) pages "
        + "(collected \(records.count) records)"
    case .zonePaginationLimitExceeded(let maxPages, let zones):
      return Self.zonePaginationDescription(maxPages: maxPages, zoneCount: zones.count)
    case .missingCredentials(let database, let availability, let reason):
      return Self.missingCredentialsDescription(
        database: database, availability: availability, reason: reason
      )
    case .invalidPrivateKey(let path, let underlying):
      let location = path.map { "from '\($0)'" } ?? "from inline material"
      return
        "Failed to load CloudKit private key \(location): \(underlying.localizedDescription)"
    case .missingAssetDownloadURL:
      return "Asset downloadURL is missing or is not a valid URL"
    case .accessDenied, .atomicFailure, .authenticationFailed, .authenticationRequired,
      .badRequest, .conflict, .exists, .internalServerError, .notFound, .quotaExceeded,
      .throttled, .tryAgainLater, .validatingReferenceError, .zoneNotFound,
      .unknownServerError:
      return serverErrorCodeDescription
    }
  }

  /// Uniform description for every case that models a CloudKit
  /// `serverErrorCode`, built from ``CloudKitError/serverErrorDetail``.
  private var serverErrorCodeDescription: String? {
    guard let detail = serverErrorDetail else {
      return nil
    }
    var message = "CloudKit \(detail.summary) (HTTP \(detail.statusCode) / \(detail.code))"
    if let reason = detail.reason {
      message += "\nReason: \(reason)"
    }
    if case .quotaExceeded(_, let hint) = self, let hint {
      message += "\nHint: \(hint.description)"
    }
    return message
  }

  private static func recordOperationDescription(_ recordError: RecordOperationFailure) -> String {
    let identifier = recordError.identifier
    let code = recordError.serverErrorCode.rawValue
    var message = "CloudKit record operation failed for '\(identifier)' (\(code))"
    if let reason = recordError.reason {
      message += "\nReason: \(reason)"
    }
    return message
  }

  private static func subscriptionOperationDescription(
    _ subscriptionError: SubscriptionOperationFailure
  ) -> String {
    let identifier = subscriptionError.identifier
    let code = subscriptionError.serverErrorCode.rawValue
    var message =
      "CloudKit subscription operation failed for '\(identifier)' (\(code))"
    if let reason = subscriptionError.reason {
      message += "\nReason: \(reason)"
    }
    return message
  }

  private static func subscriptionLikelyDuplicateDescription(
    _ subscriptionError: SubscriptionOperationFailure
  ) -> String {
    let identifier = subscriptionError.identifier
    let reasonFragment: String
    if let reason = subscriptionError.reason {
      reasonFragment = "\"\(reason)\")."
    } else {
      reasonFragment = "no reason)."
    }
    var message = "CloudKit subscription create returned INTERNAL_ERROR for '\(identifier)'."
    message += "\nLikely cause: another subscription matching this query and firesOn"
    message += " already exists (CloudKit reports semantically-duplicate"
    message += " subscriptions as INTERNAL_ERROR / "
    message += reasonFragment
    message += "\nUse listSubscriptions to find and reuse or delete the existing one."
    return message
  }

  private static func decodingErrorDescription(_ error: DecodingError) -> String {
    var message = "Failed to decode CloudKit response"
    switch error {
    case .keyNotFound(let key, let context):
      message += "\nMissing key: \(key.stringValue)"
      message += codingPathFragment(context)
    case .typeMismatch(let type, let context):
      message += "\nType mismatch: expected \(type)"
      message += codingPathFragment(context)
    case .valueNotFound(let type, let context):
      message += "\nValue not found: expected \(type)"
      message += codingPathFragment(context)
    case .dataCorrupted(let context):
      message += "\nData corrupted"
      message += codingPathFragment(context)
    @unknown default:
      message += "\nUnknown decoding error: \(error.localizedDescription)"
    }
    return message
  }

  private static func codingPathFragment(_ context: DecodingError.Context) -> String {
    var fragment = "\nCoding path: \(context.codingPath.map(\.stringValue).joined(separator: "."))"
    if let underlyingError = context.underlyingError {
      fragment += "\nUnderlying error: \(underlyingError.localizedDescription)"
    }
    return fragment
  }

  private static func missingCredentialsDescription(
    database: Database, availability: CredentialAvailability, reason: String
  ) -> String {
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
  }

  private static func simpleReasonDescription(prefix: String, reason: String?) -> String {
    var message = prefix
    if let reason {
      message += "\nReason: \(reason)"
    }
    return message
  }
}
