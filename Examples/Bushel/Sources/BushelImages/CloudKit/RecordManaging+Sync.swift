import Foundation
import MistKit

extension RecordManaging where Self: CloudKitRecordCollection {
    // MARK: - Batch Operations

    /// Sync multiple records to CloudKit in batches (convenience wrapper)
    ///
    /// **MistKit Pattern**: Records are synced in dependency order:
    /// 1. SwiftVersion (no dependencies)
    /// 2. RestoreImage (no dependencies)
    /// 3. XcodeVersion (references SwiftVersion and RestoreImage via CKReference)
    ///
    /// This ensures referenced records exist before creating records that reference them.
    ///
    /// - Note: This method calls the generic `syncAllRecords()` provided by CloudKitRecordCollection
    func syncRecords(
        restoreImages: [RestoreImageRecord],
        xcodeVersions: [XcodeVersionRecord],
        swiftVersions: [SwiftVersionRecord]
    ) async throws {
        BushelLogger.explain(
            "Syncing in dependency order: SwiftVersion → RestoreImage → XcodeVersion (prevents broken references)",
            subsystem: BushelLogger.cloudKit
        )

        // Build dictionary for generic syncAllRecords
        let recordsByType: [String: [any CloudKitRecord]] = [
            "SwiftVersion": swiftVersions,
            "RestoreImage": restoreImages,
            "XcodeVersion": xcodeVersions
        ]

        try await syncAllRecords(recordsByType)
    }
}
