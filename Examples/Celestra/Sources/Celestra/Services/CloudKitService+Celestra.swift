import Foundation
import MistKit

/// CloudKit service extensions for Celestra operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
    // MARK: - PublicFeed Operations

    /// Create a new PublicFeed record
    func createFeed(_ feed: PublicFeed) async throws -> RecordInfo {
        try await createRecord(
            recordType: "PublicFeed",
            fields: feed.toFieldsDict()
        )
    }

    /// Update an existing PublicFeed record
    func updateFeed(recordName: String, feed: PublicFeed) async throws -> RecordInfo {
        try await updateRecord(
            recordName: recordName,
            recordType: "PublicFeed",
            fields: feed.toFieldsDict()
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

    /// Create multiple PublicArticle records in a batch (non-atomic)
    func createArticles(_ articles: [PublicArticle]) async throws -> [RecordInfo] {
        guard !articles.isEmpty else {
            return []
        }

        let records = articles.map { article in
            (recordType: "PublicArticle", fields: article.toFieldsDict())
        }

        // Use non-atomic to allow partial success
        return try await createRecords(records, atomic: false)
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
