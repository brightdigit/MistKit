import Foundation
import MistKit

extension BushelCloudKitService {
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

    // MARK: - Private Helpers

    /// Execute operations in batches (CloudKit limits to 200 operations per request)
    ///
    /// **MistKit Pattern**: CloudKit has a 200 operations/request limit.
    /// This method chunks operations and calls service.modifyRecords() for each batch.
    func executeBatchOperations(
        _ operations: [RecordOperation],
        recordType: String
    ) async throws {
        let batchSize = 200
        let batches = operations.chunked(into: batchSize)

        print("Syncing \(operations.count) \(recordType) record(s) in \(batches.count) batch(es)...")
        BushelLogger.verbose(
            "CloudKit batch limit: 200 operations/request. Using \(batches.count) batch(es) for \(operations.count) records.",
            subsystem: BushelLogger.cloudKit
        )

        var totalSucceeded = 0
        var totalFailed = 0

        for (index, batch) in batches.enumerated() {
            print("  Batch \(index + 1)/\(batches.count): \(batch.count) records...")
            BushelLogger.verbose(
                "Calling MistKit service.modifyRecords() with \(batch.count) RecordOperation objects",
                subsystem: BushelLogger.cloudKit
            )

            let results = try await service.modifyRecords(batch)

            BushelLogger.verbose("Received \(results.count) RecordInfo responses from CloudKit", subsystem: BushelLogger.cloudKit)

            // Filter out error responses using isError property
            let successfulRecords = results.filter { !$0.isError }
            let failedCount = results.count - successfulRecords.count

            totalSucceeded += successfulRecords.count
            totalFailed += failedCount

            if failedCount > 0 {
                print("   ⚠️  \(failedCount) operations failed (see verbose logs for details)")
                print("   ✓ \(successfulRecords.count) records confirmed")

                // Log error details in verbose mode
                let errorRecords = results.filter { $0.isError }
                for errorRecord in errorRecords {
                    BushelLogger.verbose(
                        "Error: recordName=\(errorRecord.recordName), reason=\(errorRecord.recordType)",
                        subsystem: BushelLogger.cloudKit
                    )
                }
            } else {
                BushelLogger.success("CloudKit confirmed \(successfulRecords.count) records", subsystem: BushelLogger.cloudKit)
            }
        }

        print("\n📊 \(recordType) Sync Summary:")
        print("   Attempted: \(operations.count) operations")
        print("   Succeeded: \(totalSucceeded) records")

        if totalFailed > 0 {
            print("   ❌ Failed: \(totalFailed) operations")
            BushelLogger.explain(
                "Use --verbose flag to see CloudKit error details (serverErrorCode, reason, etc.)",
                subsystem: BushelLogger.cloudKit
            )
        }
    }
}
