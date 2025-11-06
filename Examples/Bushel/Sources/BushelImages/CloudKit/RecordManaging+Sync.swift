import Foundation
import MistKit

extension RecordManaging {
    // MARK: - Batch Operations

    /// Sync multiple records to CloudKit in batches
    ///
    /// **MistKit Pattern**: Records are synced in dependency order:
    /// 1. SwiftVersion (no dependencies)
    /// 2. RestoreImage (no dependencies)
    /// 3. XcodeVersion (references SwiftVersion and RestoreImage via CKReference)
    ///
    /// This ensures referenced records exist before creating records that reference them.
    func syncRecords(
        restoreImages: [RestoreImageRecord],
        xcodeVersions: [XcodeVersionRecord],
        swiftVersions: [SwiftVersionRecord]
    ) async throws {
        BushelLogger.explain(
            "Syncing in dependency order: SwiftVersion → RestoreImage → XcodeVersion (prevents broken references)",
            subsystem: BushelLogger.cloudKit
        )

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

    /// Sync DataSourceMetadata records to CloudKit
    func syncDataSourceMetadata(_ records: [DataSourceMetadata]) async throws {
        let operations = records.map(RecordBuilder.buildDataSourceMetadataOperation)
        try await executeBatchOperations(operations, recordType: "DataSourceMetadata")
    }
}
