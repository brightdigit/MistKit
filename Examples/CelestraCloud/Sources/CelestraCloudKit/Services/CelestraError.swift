//
//  CelestraError.swift
//  CelestraCloud
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
public import MistKit

/// Comprehensive error types for Celestra RSS operations
public enum CelestraError: LocalizedError {
  /// CloudKit operation failed
  case cloudKitError(CloudKitError)

  /// RSS feed fetch failed
  case rssFetchFailed(URL, underlying: any Error)

  /// Invalid feed data received
  case invalidFeedData(String)

  /// Batch operation failed
  case batchOperationFailed([any Error])

  /// CloudKit quota exceeded
  case quotaExceeded

  /// Network unavailable
  case networkUnavailable

  /// Permission denied for CloudKit operation
  case permissionDenied

  /// Record not found
  case recordNotFound(String)

  /// CloudKit operation failed with message
  case cloudKitOperationFailed(String)

  /// Invalid record name
  case invalidRecordName(String)

  // MARK: - Lookup Tables

  // The tables below are keyed by `caseID` (see the discriminator at the bottom
  // of this file) so that cases with associated values — which can't be written
  // as case-literal keys — participate alongside the payload-free cases.

  /// Cases that are retriable on their own. `cloudKitError` is decided
  /// separately, delegating to the wrapped `CloudKitError`.
  private static let retriableCaseIDs: Set<CaseID> = [
    .rssFetchFailed,
    .networkUnavailable,
  ]

  /// Error descriptions for cases whose text doesn't depend on associated values.
  private static let staticDescriptions: [CaseID: String] = [
    .quotaExceeded: "CloudKit quota exceeded. Please try again later.",
    .networkUnavailable: "Network unavailable. Check your connection.",
    .permissionDenied: "Permission denied for CloudKit operation.",
  ]

  /// Recovery suggestions. Cases absent here have no suggestion (`nil`).
  private static let recoverySuggestions: [CaseID: String] = [
    .rssFetchFailed: "Verify the feed URL is accessible and try again.",
    .invalidFeedData: "Verify the feed URL returns valid RSS/Atom data.",
    .quotaExceeded: "Wait a few minutes for CloudKit quota to reset, then try again.",
    .networkUnavailable: "Check your internet connection and try again.",
    .permissionDenied: "Check your CloudKit permissions and API token configuration.",
  ]

  // MARK: - Retriability

  /// Determines if this error can be retried
  public var isRetriable: Bool {
    if case .cloudKitError(let ckError) = self {
      return isCloudKitErrorRetriable(ckError)
    }
    return Self.retriableCaseIDs.contains(caseID)
  }

  // MARK: - LocalizedError Conformance

  /// Localized error description
  public var errorDescription: String? {
    // Cases without associated values get their text from the lookup table;
    // the rest interpolate their payloads.
    guard let staticDescription = Self.staticDescriptions[caseID] else {
      switch self {
      case .cloudKitError(let error):
        return "CloudKit operation failed: \(error.localizedDescription)"
      case .rssFetchFailed(let url, let error):
        return "Failed to fetch RSS feed from \(url.absoluteString): \(error.localizedDescription)"
      case .invalidFeedData(let reason):
        return "Invalid feed data: \(reason)"
      case .batchOperationFailed(let errors):
        return "Batch operation failed with \(errors.count) error(s)"
      case .recordNotFound(let recordName):
        return "Record not found: \(recordName)"
      case .cloudKitOperationFailed(let message):
        return "CloudKit operation failed: \(message)"
      case .invalidRecordName(let message):
        return "Invalid record name: \(message)"
      default:
        assertionFailure("Missing `errorDescription` for case: \(self).")
        return nil
      }
    }
    return staticDescription
  }

  /// Suggested recovery action for the error
  public var recoverySuggestion: String? { Self.recoverySuggestions[caseID] }

  // MARK: - CloudKit Error Classification

  /// Determines if a CloudKit error is retriable based on error type
  private func isCloudKitErrorRetriable(_ error: CloudKitError) -> Bool {
    switch error {
    case .httpError(let statusCode),
      .httpErrorWithDetails(let statusCode, _, _),
      .httpErrorWithRawResponse(let statusCode, _):
      // Retry on server errors (5xx) and rate limiting (429)
      // Don't retry on client errors (4xx) except 429
      return statusCode >= 500 || statusCode == 429
    // Network-related/transient errors are retriable
    case .invalidResponse, .underlyingError, .networkError:
      return true

    // Everything else (decoding, configuration, credential, malformed-request,
    // and quota errors) is not retriable.
    default:
      return false
    }
  }
}

// MARK: - Case Identity

extension CelestraError {
  /// Payload-free mirror of `CelestraError`'s cases. Used as the key into the
  /// lookup tables above so that cases with associated values can be classified
  /// without being written as case literals.
  private enum CaseID {
    case cloudKitError, rssFetchFailed, invalidFeedData, batchOperationFailed,
      quotaExceeded, networkUnavailable, permissionDenied, recordNotFound,
      cloudKitOperationFailed, invalidRecordName
  }

  private var caseID: CaseID {
    switch self {
    case .cloudKitError: .cloudKitError
    case .rssFetchFailed: .rssFetchFailed
    case .invalidFeedData: .invalidFeedData
    case .batchOperationFailed: .batchOperationFailed
    case .quotaExceeded: .quotaExceeded
    case .networkUnavailable: .networkUnavailable
    case .permissionDenied: .permissionDenied
    case .recordNotFound: .recordNotFound
    case .cloudKitOperationFailed: .cloudKitOperationFailed
    case .invalidRecordName: .invalidRecordName
    }
  }
}
