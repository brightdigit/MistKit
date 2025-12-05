import Foundation
import Logging
import MistKit

/// CloudKit service extensions for Celestra operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
    // MARK: - Feed Operations

    /// Create a new Feed record
    func createFeed(_ feed: Feed) async throws -> RecordInfo {
        CelestraLogger.cloudkit.info("📝 Creating feed: \(feed.feedURL)")

        let operation = RecordOperation.create(
            recordType: "Feed",
            recordName: UUID().uuidString,
            fields: feed.toFieldsDict()
        )
        let results = try await self.modifyRecords([operation])
        guard let record = results.first else {
            throw CloudKitError.invalidResponse
        }
        return record
    }

    /// Update an existing Feed record
    func updateFeed(recordName: String, feed: Feed) async throws -> RecordInfo {
        CelestraLogger.cloudkit.info("🔄 Updating feed: \(feed.feedURL)")

        let operation = RecordOperation.update(
            recordType: "Feed",
            recordName: recordName,
            fields: feed.toFieldsDict(),
            recordChangeTag: feed.recordChangeTag
        )
        let results = try await self.modifyRecords([operation])
        guard let record = results.first else {
            throw CloudKitError.invalidResponse
        }
        return record
    }

    /// Query feeds with optional filters (demonstrates QueryFilter and QuerySort)
    func queryFeeds(
        lastAttemptedBefore: Date? = nil,
        minPopularity: Int64? = nil,
        limit: Int = 100
    ) async throws -> [Feed] {
        var filters: [QueryFilter] = []

        // Filter by last attempted date if provided
        if let cutoff = lastAttemptedBefore {
            filters.append(.lessThan("lastAttempted", .date(cutoff)))
        }

        // Filter by minimum popularity if provided
        if let minPop = minPopularity {
            filters.append(.greaterThanOrEquals("usageCount", .int64(Int(minPop))))
        }

        // Query with filters and sort by feedURL (always queryable+sortable)
        let records = try await queryRecords(
            recordType: "Feed",
            filters: filters.isEmpty ? nil : filters,
            sortBy: [.ascending("feedURL")],  // Use feedURL since usageCount might have issues
            limit: limit
        )

        return records.map { Feed(from: $0) }
    }

    // MARK: - Article Operations

    /// Query existing articles by GUIDs for duplicate detection
    /// - Parameters:
    ///   - guids: Array of article GUIDs to check
    ///   - feedRecordName: Optional feed record name filter to scope the query
    /// - Returns: Array of existing Article records matching the GUIDs
    func queryArticlesByGUIDs(
        _ guids: [String],
        feedRecordName: String? = nil
    ) async throws -> [Article] {
        guard !guids.isEmpty else {
            return []
        }

        var filters: [QueryFilter] = []

        // Add feed filter if provided
        if let feedName = feedRecordName {
            filters.append(.equals("feed", .reference(FieldValue.Reference(recordName: feedName))))
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
                    recordType: "Article",
                    filters: filters,
                    limit: 200,
                    desiredKeys: ["guid", "contentHash", "___recordID"]
                )

                // For now, fetch all articles for this feed and filter in memory
                let allFeedArticles = records.map { Article(from: $0) }
                let guidSet = Set(guids)
                return allFeedArticles.filter { guidSet.contains($0.guid) }
            } else {
                // Just GUID filter - need to query each individually or use contentHash
                // For simplicity, query by feedRecordName first then filter
                let records = try await queryRecords(
                    recordType: "Article",
                    limit: 200,
                    desiredKeys: ["guid", "contentHash", "___recordID"]
                )

                let articles = records.map { Article(from: $0) }
                let guidSet = Set(guids)
                return articles.filter { guidSet.contains($0.guid) }
            }
        } else {
            // For large GUID sets, fetch all articles for the feed and filter in memory
            if let feedName = feedRecordName {
                filters = [.equals("feed", .reference(FieldValue.Reference(recordName: feedName)))]
            }

            let records = try await queryRecords(
                recordType: "Article",
                filters: filters.isEmpty ? nil : filters,
                limit: 200,
                desiredKeys: ["guid", "contentHash", "___recordID"]
            )

            let articles = records.map { Article(from: $0) }
            let guidSet = Set(guids)
            return articles.filter { guidSet.contains($0.guid) }
        }
    }

    /// Create multiple Article records in batches with retry logic
    /// - Parameter articles: Articles to create
    /// - Returns: Batch operation result with success/failure tracking
    func createArticles(_ articles: [Article]) async throws -> BatchOperationResult {
        guard !articles.isEmpty else {
            return BatchOperationResult()
        }

        CelestraLogger.cloudkit.info("📦 Creating \(articles.count) article(s)...")

        // Chunk articles into batches of 10 to keep payload size manageable with full content
        let batches = articles.chunked(into: 10)
        var result = BatchOperationResult()

        for (index, batch) in batches.enumerated() {
            CelestraLogger.operations.info("   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

            do {
                let operations = batch.map { article in
                    RecordOperation.create(
                        recordType: "Article",
                        recordName: UUID().uuidString,
                        fields: article.toFieldsDict()
                    )
                }

                let recordInfos = try await self.modifyRecords(operations)

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

    /// Update multiple Article records in batches with retry logic
    /// - Parameter articles: Articles to update (must have recordName set)
    /// - Returns: Batch operation result with success/failure tracking
    func updateArticles(_ articles: [Article]) async throws -> BatchOperationResult {
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

        // Chunk articles into batches of 10 to keep payload size manageable with full content
        let batches = validArticles.chunked(into: 10)
        var result = BatchOperationResult()

        for (index, batch) in batches.enumerated() {
            CelestraLogger.operations.info("   Batch \(index + 1)/\(batches.count): \(batch.count) article(s)")

            do {
                let operations = batch.compactMap { article -> RecordOperation? in
                    guard let recordName = article.recordName else { return nil }

                    return RecordOperation.update(
                        recordType: "Article",
                        recordName: recordName,
                        fields: article.toFieldsDict(),
                        recordChangeTag: nil
                    )
                }

                let recordInfos = try await self.modifyRecords(operations)

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

    /// Delete all Feed records
    func deleteAllFeeds() async throws {
        let feeds = try await queryRecords(
            recordType: "Feed",
            limit: 200,
            desiredKeys: ["___recordID"]
        )

        guard !feeds.isEmpty else {
            return
        }

        let operations = feeds.map { record in
            RecordOperation.delete(
                recordType: "Feed",
                recordName: record.recordName,
                recordChangeTag: record.recordChangeTag
            )
        }

        _ = try await modifyRecords(operations)
    }

    /// Delete all Article records
    func deleteAllArticles() async throws {
        let articles = try await queryRecords(
            recordType: "Article",
            limit: 200,
            desiredKeys: ["___recordID"]
        )

        guard !articles.isEmpty else {
            return
        }

        let operations = articles.map { record in
            RecordOperation.delete(
                recordType: "Article",
                recordName: record.recordName,
                recordChangeTag: record.recordChangeTag
            )
        }

        _ = try await modifyRecords(operations)
    }
}
