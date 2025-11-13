import Foundation
import MistKit

/// Comprehensive error types for Celestra RSS operations
enum CelestraError: LocalizedError {
  /// CloudKit operation failed
  case cloudKitError(CloudKitError)

  /// RSS feed fetch failed
  case rssFetchFailed(URL, underlying: Error)

  /// Invalid feed data received
  case invalidFeedData(String)

  /// Batch operation failed
  case batchOperationFailed([Error])

  /// CloudKit quota exceeded
  case quotaExceeded

  /// Network unavailable
  case networkUnavailable

  /// Permission denied for CloudKit operation
  case permissionDenied

  /// Record not found
  case recordNotFound(String)

  // MARK: - Retriability

  /// Determines if this error can be retried
  var isRetriable: Bool {
    switch self {
    case .cloudKitError(let ckError):
      return isCloudKitErrorRetriable(ckError)
    case .rssFetchFailed, .networkUnavailable:
      return true
    case .quotaExceeded, .invalidFeedData, .batchOperationFailed,
         .permissionDenied, .recordNotFound:
      return false
    }
  }

  // MARK: - LocalizedError Conformance

  var errorDescription: String? {
    switch self {
    case .cloudKitError(let error):
      return "CloudKit operation failed: \(error.localizedDescription)"
    case .rssFetchFailed(let url, let error):
      return "Failed to fetch RSS feed from \(url.absoluteString): \(error.localizedDescription)"
    case .invalidFeedData(let reason):
      return "Invalid feed data: \(reason)"
    case .batchOperationFailed(let errors):
      return "Batch operation failed with \(errors.count) error(s)"
    case .quotaExceeded:
      return "CloudKit quota exceeded. Please try again later."
    case .networkUnavailable:
      return "Network unavailable. Check your connection."
    case .permissionDenied:
      return "Permission denied for CloudKit operation."
    case .recordNotFound(let recordName):
      return "Record not found: \(recordName)"
    }
  }

  var recoverySuggestion: String? {
    switch self {
    case .quotaExceeded:
      return "Wait a few minutes for CloudKit quota to reset, then try again."
    case .networkUnavailable:
      return "Check your internet connection and try again."
    case .rssFetchFailed:
      return "Verify the feed URL is accessible and try again."
    case .permissionDenied:
      return "Check your CloudKit permissions and API token configuration."
    case .invalidFeedData:
      return "Verify the feed URL returns valid RSS/Atom data."
    case .cloudKitError, .batchOperationFailed, .recordNotFound:
      return nil
    }
  }

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
    case .invalidResponse, .underlyingError:
      // Network-related errors are retriable
      return true
    case .networkError:
      // Network errors are retriable
      return true
    case .decodingError:
      // Decoding errors are not retriable (data format issue)
      return false
    }
  }
}
