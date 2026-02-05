//
//  ArticleCloudKitService.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import CelestraKit
public import Foundation
import Logging
public import MistKit

// swiftlint:disable file_length

// MARK: - CloudKit Batch Size Constants

/// Maximum number of GUIDs per CloudKit query operation.
///
/// CloudKit supports up to 200 records per batch, but GUID queries using the IN operator
/// benefit from smaller batches to avoid query complexity limits. 150 GUIDs provides
/// optimal balance between query efficiency and avoiding CloudKit rate limits.
private let guidQueryBatchSize = 150

/// Maximum number of articles per CloudKit create/update operation.
///
/// While CloudKit supports up to 200 records per batch, articles contain full HTML content
/// which creates large payloads. Conservative batching at 10 articles prevents:
/// - Payload size limits (CloudKit max request: ~10MB)
/// - Timeout issues with slow network connections
/// - All-or-nothing failure affecting too many records
///
/// Non-atomic operations allow partial success within each batch.
private let articleMutationBatchSize = 10

/// Service for Article-related CloudKit operations with dependency injection support
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct ArticleCloudKitService: Sendable {
  private enum BatchOperation {
    case create
    case update
  }
  private let recordOperator: any CloudKitRecordOperating
  private let operationBuilder: ArticleOperationBuilder

  /// Creates a new Article CloudKit service with dependency injection.
  ///
  /// - Parameters:
  ///   - recordOperator: The CloudKit record operator for performing database operations
  ///   - operationBuilder: Builder for creating article record operations
  ///     (defaults to ArticleOperationBuilder())
  public init(
    recordOperator: any CloudKitRecordOperating,
    operationBuilder: ArticleOperationBuilder = ArticleOperationBuilder()
  ) {
    self.recordOperator = recordOperator
    self.operationBuilder = operationBuilder
  }

  // MARK: - Query Operations
  /// Queries articles from CloudKit by their GUIDs with optional feed filtering.
  ///
  /// Automatically batches large queries into optimal groups to stay within CloudKit limits.
  /// See `guidQueryBatchSize` constant for batch sizing rationale.
  /// Invalid article records are logged and skipped rather than failing the entire query.
  ///
  /// - Parameters:
  ///   - guids: Array of article GUIDs to query
  ///   - feedRecordName: Optional feed record name to filter results to a specific feed
  /// - Returns: Array of successfully parsed Article objects
  /// - Throws: CloudKitError if the query operation fails
  public func queryArticlesByGUIDs(
    _ guids: [String],
    feedRecordName: String? = nil
  ) async throws(CloudKitError) -> [Article] {
    guard !guids.isEmpty else {
      return []
    }
    var allArticles: [Article] = []
    let guidBatches = guids.chunked(into: guidQueryBatchSize)
    for batch in guidBatches {
      let batchArticles = try await queryArticleBatch(batch, feedRecordName: feedRecordName)
      allArticles.append(contentsOf: batchArticles)
    }
    return allArticles
  }

  private func queryArticleBatch(
    _ guids: [String],
    feedRecordName: String?
  ) async throws(CloudKitError) -> [Article] {
    // CloudKit Web Services has issues with combining .in() with other filters.
    // Current approach: Use .in() ONLY for GUID filtering (single filter, no combinations).
    // Feed filtering is done in-memory (line 135-136) to avoid the .in() + filter issue.
    //
    // Known limitation: Cannot efficiently query by both GUID and feedRecordName in one query.
    // This is acceptable because GUID queries are typically small batches (<150 items).
    //
    // Alternative considered: Multiple single-GUID queries would be significantly slower
    // and hit rate limits faster. The in-memory filter is the pragmatic solution.
    let filters: [QueryFilter] = [.in("guid", guids.map { FieldValue.string($0) })]
    let records = try await recordOperator.queryRecords(
      recordType: "Article",
      filters: filters,
      sortBy: nil,
      limit: 200,
      desiredKeys: nil
    )
    let articles = records.compactMap { record in
      do {
        return try Article(from: record)
      } catch {
        CelestraLogger.errors.warning(
          "Skipping invalid article record \(record.recordName): \(error)"
        )
        return nil
      }
    }

    // Filter by feedRecordName in-memory if specified
    if let feedName = feedRecordName {
      return articles.filter { $0.feedRecordName == feedName }
    }
    return articles
  }

  // MARK: - Create Operations
  /// Creates new articles in CloudKit with batch processing.
  ///
  /// Articles are processed in conservative batches to manage payload size and prevent timeouts.
  /// See `articleMutationBatchSize` constant for batch sizing rationale.
  /// Non-atomic operations allow partial success - some articles may succeed while others fail.
  /// All successes and failures are tracked in the returned BatchOperationResult.
  ///
  /// - Parameter articles: Array of Article objects to create in CloudKit
  /// - Returns: BatchOperationResult containing success/failure counts and detailed tracking
  /// - Throws: CloudKitError if a batch operation fails
  public func createArticles(_ articles: [Article]) async throws(CloudKitError)
    -> BatchOperationResult
  {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }
    CelestraLogger.cloudkit.info("Creating \(articles.count) article(s)...")
    let articleBatches = articles.chunked(into: articleMutationBatchSize)
    var result = BatchOperationResult()
    for (index, batch) in articleBatches.enumerated() {
      try await processBatch(
        batch,
        index: index,
        total: articleBatches.count,
        result: &result,
        operation: .create
      )
    }
    let rate = String(format: "%.1f", result.successRate)
    CelestraLogger.cloudkit.info(
      "Batch complete: \(result.successCount)/\(result.totalProcessed) (\(rate)%)"
    )
    return result
  }

  // MARK: - Update Operations
  /// Updates existing articles in CloudKit with batch processing.
  ///
  /// Articles without a recordName are automatically skipped with a warning.
  /// Remaining articles are processed in conservative batches to manage payload size and prevent timeouts.
  /// See `articleMutationBatchSize` constant for batch sizing rationale.
  /// Non-atomic operations allow partial success - some updates may succeed while others fail.
  ///
  /// - Parameter articles: Array of Article objects to update (must have recordName set)
  /// - Returns: BatchOperationResult containing success/failure counts and detailed tracking
  /// - Throws: CloudKitError if a batch operation fails
  public func updateArticles(_ articles: [Article]) async throws(CloudKitError)
    -> BatchOperationResult
  {
    guard !articles.isEmpty else {
      return BatchOperationResult()
    }
    CelestraLogger.cloudkit.info("Updating \(articles.count) article(s)...")
    let validArticles = articles.filter { $0.recordName != nil }
    if validArticles.count != articles.count {
      CelestraLogger.errors.warning(
        "Skipping \(articles.count - validArticles.count) article(s) without recordName"
      )
    }
    guard !validArticles.isEmpty else {
      return BatchOperationResult()
    }
    let batches = validArticles.chunked(into: articleMutationBatchSize)
    var result = BatchOperationResult()
    for (index, batch) in batches.enumerated() {
      try await processBatch(
        batch,
        index: index,
        total: batches.count,
        result: &result,
        operation: .update
      )
    }
    let updateRateFormatted = String(format: "%.1f", result.successRate)
    let updateSummary = "\(result.successCount)/\(result.totalProcessed) succeeded"
    CelestraLogger.cloudkit.info("Update complete: \(updateSummary) (\(updateRateFormatted)%)")
    return result
  }

  /// Processes a single batch of articles with comprehensive error tracking.
  ///
  /// ## Batch Failure Behavior
  ///
  /// When `modifyRecords` fails, all articles in the batch are marked as failed with the
  /// same error. This is a conservative approach that simplifies error handling.
  ///
  /// CloudKit batch operations can fail completely (network errors, authentication issues,
  /// rate limits) or partially (some records succeed, others fail). The current implementation
  /// treats all batch failures as complete failures.
  ///
  /// ## Future Enhancement Opportunity
  ///
  /// CloudKit's error responses can contain per-record errors via `CKErrorPartialFailure`.
  /// Parsing these would enable finer-grained failure tracking for partial successes.
  ///
  /// ## Impact on Users
  ///
  /// - Failed batches are logged with batch number for debugging
  /// - `BatchOperationResult` provides success rate and detailed failure list
  /// - Users can retry failed articles by filtering `result.failedRecords`
  ///
  /// - Parameters:
  ///   - batch: Articles to process in this batch
  ///   - index: Zero-based batch index for logging
  ///   - total: Total number of batches for progress reporting
  ///   - result: Mutable result accumulator for success/failure tracking
  ///   - operation: Type of operation (create or update)
  /// - Throws: CloudKitError if the batch operation fails
  private func processBatch(
    _ batch: [Article],
    index: Int,
    total: Int,
    result: inout BatchOperationResult,
    operation: BatchOperation
  ) async throws(CloudKitError) {
    CelestraLogger.operations.info(
      "   Batch \(index + 1)/\(total): \(batch.count) article(s)"
    )
    do {
      let operations: [RecordOperation] =
        switch operation {
        case .create:
          operationBuilder.buildCreateOperations(batch)
        case .update:
          operationBuilder.buildUpdateOperations(batch).operations
        }
      let recordInfos = try await recordOperator.modifyRecords(operations)
      result.appendSuccesses(recordInfos)
      let verb = operation == .create ? "created" : "updated"
      CelestraLogger.cloudkit.info(
        "   Batch \(index + 1) complete: \(recordInfos.count) \(verb)"
      )
    } catch {
      // Batch-level failure: All articles marked as failed (conservative approach)
      // CloudKit partial failures could allow some successes - see method documentation
      CelestraLogger.errors.error("   Batch \(index + 1) failed: \(error.localizedDescription)")
      for article in batch {
        result.appendFailure(article: article, error: error)
      }
    }
  }

  // MARK: - Delete Operations
  /// Deletes all articles from CloudKit in batches.
  ///
  /// Queries and deletes articles in batches of 200 until no more articles remain.
  /// This prevents CloudKit query limits and manages memory usage for large datasets.
  /// Progress is logged after each batch deletion.
  ///
  /// - Throws: CloudKitError if a query or delete operation fails
  public func deleteAllArticles() async throws(CloudKitError) {
    var totalDeleted = 0
    while true {
      let deletedCount = try await deleteArticleBatch()
      guard deletedCount > 0 else {
        break
      }
      totalDeleted += deletedCount
      CelestraLogger.operations.info("Deleted \(deletedCount) articles (total: \(totalDeleted))")
      if deletedCount < 200 {
        break
      }
    }
    CelestraLogger.cloudkit.info("Deleted \(totalDeleted) total articles")
  }

  private func deleteArticleBatch() async throws(CloudKitError) -> Int {
    let articles = try await recordOperator.queryRecords(
      recordType: "Article",
      filters: nil,
      sortBy: nil,
      limit: 200,
      desiredKeys: ["___recordID"]
    )
    guard !articles.isEmpty else {
      return 0
    }
    let operations = operationBuilder.buildDeleteOperations(articles)
    _ = try await recordOperator.modifyRecords(operations)
    return articles.count
  }
}
