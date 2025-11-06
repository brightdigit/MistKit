import Foundation
import MistKit

extension BushelCloudKitService {
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
}
