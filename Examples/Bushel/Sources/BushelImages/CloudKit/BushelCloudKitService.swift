import Foundation
import MistKit

/// CloudKit service wrapper for Bushel demo operations
struct BushelCloudKitService: Sendable {
    let service: CloudKitService

    // MARK: - Initialization

    init(containerIdentifier: String, apiToken: String) throws {
        let tokenManager = APITokenManager(apiToken: apiToken)
        self.service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: .development,
            database: .public
        )
    }

    // MARK: - Batch Operations

    /// Sync multiple records to CloudKit in batches
    func syncRecords(
        restoreImages: [RestoreImageRecord],
        xcodeVersions: [XcodeVersionRecord],
        swiftVersions: [SwiftVersionRecord]
    ) async throws {
        // Sync in order: Swift -> RestoreImages -> Xcode (due to references)
        try await syncSwiftVersions(swiftVersions)
        try await syncRestoreImages(restoreImages)
        try await syncXcodeVersions(xcodeVersions)
    }

    // MARK: - Individual Type Operations

    /// Sync RestoreImage records to CloudKit
    func syncRestoreImages(_ records: [RestoreImageRecord]) async throws {
        let operations = records.map(RecordBuilder.buildRestoreImageOperation)
        try await executeBatchOperations(operations, recordType: "RestoreImage")
    }

    /// Sync XcodeVersion records to CloudKit
    func syncXcodeVersions(_ records: [XcodeVersionRecord]) async throws {
        let operations = records.map(RecordBuilder.buildXcodeVersionOperation)
        try await executeBatchOperations(operations, recordType: "XcodeVersion")
    }

    /// Sync SwiftVersion records to CloudKit
    func syncSwiftVersions(_ records: [SwiftVersionRecord]) async throws {
        let operations = records.map(RecordBuilder.buildSwiftVersionOperation)
        try await executeBatchOperations(operations, recordType: "SwiftVersion")
    }

    // MARK: - Query Operations

    /// Query all records of a given type
    func queryRecords(recordType: String) async throws -> [RecordInfo] {
        try await service.queryRecords(recordType: recordType, limit: 1000)
    }

    // MARK: - Private Helpers

    /// Execute operations in batches (CloudKit limits to 200 operations per request)
    private func executeBatchOperations(
        _ operations: [RecordOperation],
        recordType: String
    ) async throws {
        let batchSize = 200
        let batches = operations.chunked(into: batchSize)

        print("Syncing \(operations.count) \(recordType) record(s) in \(batches.count) batch(es)...")

        for (index, batch) in batches.enumerated() {
            print("  Batch \(index + 1)/\(batches.count): \(batch.count) records...")
            _ = try await service.modifyRecords(batch)
        }

        print("✅ Synced \(operations.count) \(recordType) records")
    }
}

// MARK: - Array Extension

private extension Array {
    /// Split array into chunks of specified size
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
