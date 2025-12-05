import Foundation
import MistKit

/// Result of a batch CloudKit operation
struct BatchOperationResult {
  /// Successfully created/updated records
  var successfulRecords: [RecordInfo] = []

  /// Records that failed to process
  var failedRecords: [(article: Article, error: Error)] = []

  /// Total number of records processed (success + failure)
  var totalProcessed: Int {
    successfulRecords.count + failedRecords.count
  }

  /// Number of successful operations
  var successCount: Int {
    successfulRecords.count
  }

  /// Number of failed operations
  var failureCount: Int {
    failedRecords.count
  }

  /// Success rate as a percentage (0-100)
  var successRate: Double {
    guard totalProcessed > 0 else { return 0 }
    return Double(successCount) / Double(totalProcessed) * 100
  }

  /// Whether all operations succeeded
  var isFullSuccess: Bool {
    failureCount == 0 && successCount > 0
  }

  /// Whether all operations failed
  var isFullFailure: Bool {
    successCount == 0 && failureCount > 0
  }

  // MARK: - Mutation

  /// Append results from another batch operation
  mutating func append(_ other: BatchOperationResult) {
    successfulRecords.append(contentsOf: other.successfulRecords)
    failedRecords.append(contentsOf: other.failedRecords)
  }

  /// Append successful records
  mutating func appendSuccesses(_ records: [RecordInfo]) {
    successfulRecords.append(contentsOf: records)
  }

  /// Append a failure
  mutating func appendFailure(article: Article, error: Error) {
    failedRecords.append((article, error))
  }
}
