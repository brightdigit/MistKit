import Foundation
import MistKit

/// CloudKit service wrapper for Bushel demo operations
///
/// **Tutorial**: This demonstrates MistKit's Server-to-Server authentication pattern:
/// 1. Load ECDSA private key from .pem file
/// 2. Create ServerToServerAuthManager with key ID and PEM string
/// 3. Initialize CloudKitService with the auth manager
/// 4. Use service.modifyRecords() and service.queryRecords() for operations
///
/// This pattern allows command-line tools and servers to access CloudKit without user authentication.
struct BushelCloudKitService: Sendable {
    let service: CloudKitService

    // MARK: - Initialization

    /// Initialize CloudKit service with Server-to-Server authentication
    ///
    /// **MistKit Pattern**: Server-to-Server authentication requires:
    /// 1. Key ID from CloudKit Dashboard → API Access → Server-to-Server Keys
    /// 2. Private key .pem file downloaded when creating the key
    /// 3. Container identifier (begins with "iCloud.")
    ///
    /// - Parameters:
    ///   - containerIdentifier: CloudKit container ID (e.g., "iCloud.com.company.App")
    ///   - keyID: Server-to-Server Key ID from CloudKit Dashboard
    ///   - privateKeyPath: Path to the private key .pem file
    /// - Throws: Error if the private key file cannot be read or is invalid
    init(containerIdentifier: String, keyID: String, privateKeyPath: String) throws {
        // Read PEM file from disk
        guard FileManager.default.fileExists(atPath: privateKeyPath) else {
            throw BushelCloudKitError.privateKeyFileNotFound(path: privateKeyPath)
        }

        let pemString: String
        do {
            pemString = try String(contentsOfFile: privateKeyPath, encoding: .utf8)
        } catch {
            throw BushelCloudKitError.privateKeyFileReadFailed(path: privateKeyPath, error: error)
        }

        // Create Server-to-Server authentication manager
        let tokenManager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: pemString
        )

        self.service = try CloudKitService(
            containerIdentifier: containerIdentifier,
            tokenManager: tokenManager,
            environment: .development,
            database: .public
        )
    }

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

    // MARK: - Query Operations

    /// Query all records of a given type
    func queryRecords(recordType: String) async throws -> [RecordInfo] {
        try await service.queryRecords(recordType: recordType, limit: 1000)
    }

    /// Query a specific DataSourceMetadata record
    ///
    /// **MistKit Pattern**: Query all metadata records and filter by record name
    /// Record name format: "metadata-{sourceName}-{recordType}"
    func queryDataSourceMetadata(source: String, recordType: String) async throws -> DataSourceMetadata? {
        let targetRecordName = "metadata-\(source)-\(recordType)"
        let results = try await service.queryRecords(
            recordType: "DataSourceMetadata",
            limit: 1000
        )

        // Find the specific record we're looking for
        guard let record = results.first(where: { $0.recordName == targetRecordName }) else {
            return nil
        }

        // Parse the CloudKit record back into DataSourceMetadata
        return try parseDataSourceMetadata(from: record)
    }

    // MARK: - Delete Operations

    /// Delete all records from CloudKit (for all record types)
    func deleteAllRecords() async throws {
        BushelLogger.info("🗑️  Deleting all records from CloudKit", subsystem: BushelLogger.cloudKit)
        BushelLogger.explain(
            "Querying all record types then deleting in batches using RecordOperation.delete()",
            subsystem: BushelLogger.cloudKit
        )

        // Query all records for each type
        print("\n📥 Fetching records to delete...")
        let restoreImages = try await queryRecords(recordType: "RestoreImage")
        let xcodeVersions = try await queryRecords(recordType: "XcodeVersion")
        let swiftVersions = try await queryRecords(recordType: "SwiftVersion")

        let totalRecords = restoreImages.count + xcodeVersions.count + swiftVersions.count
        print("   Found \(totalRecords) total records")
        print("   • RestoreImage: \(restoreImages.count)")
        print("   • XcodeVersion: \(xcodeVersions.count)")
        print("   • SwiftVersion: \(swiftVersions.count)")

        guard totalRecords > 0 else {
            print("\n✅ No records to delete")
            return
        }

        // Delete in dependency order (reverse of sync): Xcode -> RestoreImages -> Swift
        try await deleteRecords(xcodeVersions, recordType: "XcodeVersion")
        try await deleteRecords(restoreImages, recordType: "RestoreImage")
        try await deleteRecords(swiftVersions, recordType: "SwiftVersion")

        BushelLogger.success("All records deleted successfully!", subsystem: BushelLogger.cloudKit)
    }

    /// Delete specific records from CloudKit
    private func deleteRecords(_ records: [RecordInfo], recordType: String) async throws {
        guard !records.isEmpty else { return }

        let deleteOps = records.map { record in
            RecordOperation.delete(
                recordType: record.recordType,
                recordName: record.recordName
            )
        }

        try await executeBatchOperations(deleteOps, recordType: recordType)
    }

    // MARK: - Private Helpers

    /// Parse a CloudKit RecordInfo into DataSourceMetadata
    private func parseDataSourceMetadata(from record: RecordInfo) throws -> DataSourceMetadata {
        guard let sourceName = record.fields["sourceName"]?.stringValue,
              let recordTypeName = record.fields["recordTypeName"]?.stringValue,
              let lastFetchedAt = record.fields["lastFetchedAt"]?.dateValue
        else {
            throw BushelCloudKitError.invalidMetadataRecord(recordName: record.recordName)
        }

        let sourceUpdatedAt = record.fields["sourceUpdatedAt"]?.dateValue
        let recordCount = record.fields["recordCount"]?.int64Value ?? 0
        let fetchDurationSeconds = record.fields["fetchDurationSeconds"]?.doubleValue ?? 0
        let lastError = record.fields["lastError"]?.stringValue

        return DataSourceMetadata(
            sourceName: sourceName,
            recordTypeName: recordTypeName,
            lastFetchedAt: lastFetchedAt,
            sourceUpdatedAt: sourceUpdatedAt,
            recordCount: recordCount,
            fetchDurationSeconds: fetchDurationSeconds,
            lastError: lastError
        )
    }

    /// Execute operations in batches (CloudKit limits to 200 operations per request)
    ///
    /// **MistKit Pattern**: CloudKit has a 200 operations/request limit.
    /// This method chunks operations and calls service.modifyRecords() for each batch.
    private func executeBatchOperations(
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

            // Filter out error responses (they have recordType == "Unknown")
            let successfulRecords = results.filter { $0.recordType != "Unknown" }
            let failedCount = results.count - successfulRecords.count

            totalSucceeded += successfulRecords.count
            totalFailed += failedCount

            if failedCount > 0 {
                print("   ⚠️  \(failedCount) operations failed (see verbose logs for details)")
                print("   ✓ \(successfulRecords.count) records confirmed")

                // Log error details in verbose mode
                let errorRecords = results.filter { $0.recordType == "Unknown" }
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

// MARK: - Errors

enum BushelCloudKitError: LocalizedError {
    case privateKeyFileNotFound(path: String)
    case privateKeyFileReadFailed(path: String, error: Error)
    case invalidMetadataRecord(recordName: String)

    var errorDescription: String? {
        switch self {
        case .privateKeyFileNotFound(let path):
            return "Private key file not found at path: \(path)"
        case .privateKeyFileReadFailed(let path, let error):
            return "Failed to read private key file at \(path): \(error.localizedDescription)"
        case .invalidMetadataRecord(let recordName):
            return "Invalid DataSourceMetadata record: \(recordName) (missing required fields)"
        }
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
