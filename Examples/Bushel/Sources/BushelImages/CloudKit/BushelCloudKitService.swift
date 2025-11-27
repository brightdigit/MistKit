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
struct BushelCloudKitService: Sendable, RecordManaging, CloudKitRecordCollection {
    private let service: CloudKitService

    // MARK: - CloudKitRecordCollection

    /// All CloudKit record types managed by this service (using variadic generics)
    static let recordTypes = RecordTypeSet(
        RestoreImageRecord.self,
        XcodeVersionRecord.self,
        SwiftVersionRecord.self,
        DataSourceMetadata.self
    )

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

    // MARK: - RecordManaging Protocol Requirements

    /// Query all records of a given type
    func queryRecords(recordType: String) async throws -> [RecordInfo] {
        try await service.queryRecords(recordType: recordType, limit: 200)
    }

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
