import Foundation
import MistKit
import os

/// CloudKit service extensions for Celestra operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
    /// Retry policy for CloudKit operations
    private static let retryPolicy = RetryPolicy.default
    // MARK: - PublicFeed Operations

    /// Create a new PublicFeed record with retry logic
    func createFeed(_ feed: PublicFeed) async throws -> RecordInfo {
        CelestraLogger.cloudkit.info("📝 Creating feed: \(feed.feedURL)")

        return try await Self.retryPolicy.execute(
            operation: {
                try await self.createRecord(
                    recordType: "PublicFeed",
                    fields: feed.toFieldsDict()
                )
            },
            logger: CelestraLogger.cloudkit
        )
    }

    /// Update an existing PublicFeed record with retry logic
    func updateFeed(recordName: String, feed: PublicFeed) async throws -> RecordInfo {
        CelestraLogger.cloudkit.info("🔄 Updating feed: \(feed.feedURL)")

        return try await Self.retryPolicy.execute(
            operation: {
                try await self.updateRecord(
                    recordName: recordName,
                    recordType: "PublicFeed",
                    fields: feed.toFieldsDict()
                )
            },
            logger: CelestraLogger.cloudkit
        )
    }

    /// Query feeds with optional filters (demonstrates QueryFilter and QuerySort)
    func queryFeeds(
        lastAttemptedBefore: Date? = nil,
        minPopularity: Int64? = nil,
        limit: Int = 100
    ) async throws -> [PublicFeed] {
        var filters: [QueryFilter] = []

        // Filter by last attempted date if provided
        if let cutoff = lastAttemptedBefore {
            filters.append(.lessThan("lastAttempted", .date(cutoff)))
        }

        // Filter by minimum popularity if provided
        if let minPop = minPopularity {
            filters.append(.greaterThanOrEquals("usageCount", .int64(Int(minPop))))
        }

        // Query with filters and sort by popularity (descending)
        let records = try await queryRecords(
            recordType: "PublicFeed",
            filters: filters.isEmpty ? nil : filters,
            sortBy: [.descending("usageCount")],
            limit: limit
        )

        return records.map { PublicFeed(from: $0) }
    }

    // MARK: - PublicArticle Operations

    /// Query existing articles by GUIDs for duplicate detection
    /// - Parameters:
    ///   - guids: Array of article GUIDs to check
    ///   - feedRecordName: Optional feed filter to scope the query
    /// - Returns: Array of existing PublicArticle records matching the GUIDs
    func queryArticlesByGUIDs(
        _ guids: [String],
        feedRecordName: String? = nil
    ) async throws -> [PublicArticle] {
        guard !guids.isEmpty else {
            return []
        }

        var filters: [QueryFilter] = []

        // Add feed filter if provided
        if let feedName = feedRecordName {
            filters.append(.equals("feedRecordName", .string(feedName)))
        }

        // For small number of GUIDs, we can query directly
        // For larger sets, might need multiple queries or alternative strategy
        if guids.count <= 10 {
            // Create OR filter for GUIDs
            let guidFilters = guids.map { guid in
                QueryFilter.equals("guid", .string(guid))
            }

            // Combine with feed filter if present
            if !filters.isEmpty {
                // When we have both feed and GUID filters, we need to do multiple queries
                // or fetch all for feed and filter in memory
                filters.append(.equals("guid", .string(guids[0])))

                let records = try await queryRecords(
                    recordType: "PublicArticle",
                    filters: filters,
                    limit: 500
                )

                // For now, fetch all articles for this feed and filter in memory
                let allFeedArticles = records.map { PublicArticle(from: $0) }
                let guidSet = Set(guids)
                return allFeedArticles.filter { guidSet.contains($0.guid) }
            } else {
                // Just GUID filter - need to query each individually or use contentHash
                // For simplicity, query by feedRecordName first then filter
                let records = try await queryRecords(
                    recordType: "PublicArticle",
                    limit: 500
                )

                let articles = records.map { PublicArticle(from: $0) }
                let guidSet = Set(guids)
                return articles.filter { guidSet.contains($0.guid) }
            }
        } else {
            // For large GUID sets, fetch all articles for the feed and filter in memory
            if let feedName = feedRecordName {
                filters = [.equals("feedRecordName", .string(feedName))]
            }

            let records = try await queryRecords(
                recordType: "PublicArticle",
                filters: filters.isEmpty ? nil : filters,
                limit: 500
            )

            let articles = records.map { PublicArticle(from: $0) }
            let guidSet = Set(guids)
            return articles.filter { guidSet.contains($0.guid) }
        }
    }

    /// Create multiple PublicArticle records in batches with retry logic
    /// - Parameter articles: Articles to create
    /// - Returns: Batch operation result with success/failure tracking
    func createArticles(_ articles: [PublicArticle]) async throws -> BatchOperationResult {
        guard !articles.isEmpty else {
            return BatchOperationResult()
        }

        CelestraLogger.cloudkit.info("📦 Creating \(articles.count) article(s)...")

        // Chunk articles into batches of 200 (CloudKit limit)
        let batches = articles.chunked(into: 200)
        var result = BatchOperationResult()

        for (index, batch) in batches.enumerated() {
            CelestraLogger.operations.info("   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

            do {
                let records = batch.map { article in
                    (recordType: "PublicArticle", fields: article.toFieldsDict())
                }

                // Use retry policy for each batch
                let recordInfos = try await Self.retryPolicy.execute(
                    operation: {
                        try await self.createRecords(records, atomic: false)
                    },
                    logger: CelestraLogger.cloudkit
                )

                result.appendSuccesses(recordInfos)
                CelestraLogger.cloudkit.info("   ✅ Batch \(index + 1) complete: \(recordInfos.count) created")
            } catch {
                CelestraLogger.errors.error("   ❌ Batch \(index + 1) failed: \(error.localizedDescription)")

                // Track individual failures
                for article in batch {
                    result.appendFailure(article: article, error: error)
                }
            }
        }

        CelestraLogger.cloudkit.info(
            "📊 Batch operation complete: \(result.successCount)/\(result.totalProcessed) succeeded (\(String(format: "%.1f", result.successRate))%)"
        )

        return result
    }

    /// Update multiple PublicArticle records in batches with retry logic
    /// - Parameter articles: Articles to update (must have recordName set)
    /// - Returns: Batch operation result with success/failure tracking
    func updateArticles(_ articles: [PublicArticle]) async throws -> BatchOperationResult {
        guard !articles.isEmpty else {
            return BatchOperationResult()
        }

        CelestraLogger.cloudkit.info("🔄 Updating \(articles.count) article(s)...")

        // Filter out articles without recordName
        let validArticles = articles.filter { $0.recordName != nil }
        if validArticles.count != articles.count {
            CelestraLogger.errors.warning(
                "⚠️ Skipping \(articles.count - validArticles.count) article(s) without recordName"
            )
        }

        guard !validArticles.isEmpty else {
            return BatchOperationResult()
        }

        // Chunk articles into batches of 200
        let batches = validArticles.chunked(into: 200)
        var result = BatchOperationResult()

        for (index, batch) in batches.enumerated() {
            CelestraLogger.operations.info("   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

            do {
                let operations = batch.compactMap { article -> RecordOperation? in
                    guard let recordName = article.recordName else { return nil }

                    return RecordOperation.update(
                        recordType: "PublicArticle",
                        recordName: recordName,
                        fields: article.toFieldsDict(),
                        recordChangeTag: nil
                    )
                }

                // Use retry policy for each batch
                let recordInfos = try await Self.retryPolicy.execute(
                    operation: {
                        try await self.modifyRecords(operations)
                    },
                    logger: CelestraLogger.cloudkit
                )

                result.appendSuccesses(recordInfos)
                CelestraLogger.cloudkit.info("   ✅ Batch \(index + 1) complete: \(recordInfos.count) updated")
            } catch {
                CelestraLogger.errors.error("   ❌ Batch \(index + 1) failed: \(error.localizedDescription)")

                // Track individual failures
                for article in batch {
                    result.appendFailure(article: article, error: error)
                }
            }
        }

        CelestraLogger.cloudkit.info(
            "📊 Update complete: \(result.successCount)/\(result.totalProcessed) succeeded (\(String(format: "%.1f", result.successRate))%)"
        )

        return result
    }

    // MARK: - Cleanup Operations

    /// Delete all PublicFeed records
    func deleteAllFeeds() async throws {
        let feeds = try await queryRecords(
            recordType: "PublicFeed",
            limit: 200
        )

        guard !feeds.isEmpty else {
            return
        }

        let records = feeds.map { record in
            (recordName: record.recordName, recordType: "PublicFeed")
        }

        _ = try await deleteRecords(records, atomic: false)
    }

    /// Delete all PublicArticle records
    func deleteAllArticles() async throws {
        let articles = try await queryRecords(
            recordType: "PublicArticle",
            limit: 500
        )

        guard !articles.isEmpty else {
            return
        }

        let records = articles.map { record in
            (recordName: record.recordName, recordType: "PublicArticle")
        }

        _ = try await deleteRecords(records, atomic: false)
    }
}
