import Foundation
import MistKit

/// Orchestrates the complete sync process from data sources to CloudKit
struct SyncEngine: Sendable {
    let cloudKitService: BushelCloudKitService
    let pipeline: DataSourcePipeline

    // MARK: - Configuration

    struct SyncOptions: Sendable {
        var dryRun: Bool = false
        var pipelineOptions: DataSourcePipeline.Options = .init()
    }

    // MARK: - Initialization

    init(containerIdentifier: String, apiToken: String) throws {
        self.cloudKitService = try BushelCloudKitService(
            containerIdentifier: containerIdentifier,
            apiToken: apiToken
        )
        self.pipeline = DataSourcePipeline()
    }

    // MARK: - Sync Operations

    /// Execute full sync from all data sources to CloudKit
    func sync(options: SyncOptions = SyncOptions()) async throws -> SyncResult {
        print("\n" + String(repeating: "=", count: 60))
        print("🔄 Starting Bushel CloudKit Sync")
        print(String(repeating: "=", count: 60))

        if options.dryRun {
            print("🧪 DRY RUN MODE - No changes will be made to CloudKit")
        }

        // Step 1: Fetch from all data sources
        print("\n📥 Step 1: Fetching data from external sources...")
        let fetchResult = try await pipeline.fetch(options: options.pipelineOptions)

        let stats = SyncResult(
            restoreImagesCount: fetchResult.restoreImages.count,
            xcodeVersionsCount: fetchResult.xcodeVersions.count,
            swiftVersionsCount: fetchResult.swiftVersions.count
        )

        print("✅ Fetched:")
        print("   • \(stats.restoreImagesCount) restore images")
        print("   • \(stats.xcodeVersionsCount) Xcode versions")
        print("   • \(stats.swiftVersionsCount) Swift versions")

        // Step 2: Sync to CloudKit (unless dry run)
        if !options.dryRun {
            print("\n☁️  Step 2: Syncing to CloudKit...")
            try await cloudKitService.syncRecords(
                restoreImages: fetchResult.restoreImages,
                xcodeVersions: fetchResult.xcodeVersions,
                swiftVersions: fetchResult.swiftVersions
            )
        } else {
            print("\n⏭️  Step 2: Skipped (dry run)")
            print("   Would sync:")
            print("   • \(stats.restoreImagesCount) restore images")
            print("   • \(stats.xcodeVersionsCount) Xcode versions")
            print("   • \(stats.swiftVersionsCount) Swift versions")
        }

        print("\n" + String(repeating: "=", count: 60))
        print("✅ Sync completed successfully!")
        print(String(repeating: "=", count: 60))

        return stats
    }

    /// Export all records from CloudKit to a structured format
    func export() async throws -> ExportResult {
        print("\n" + String(repeating: "=", count: 60))
        print("📤 Exporting data from CloudKit")
        print(String(repeating: "=", count: 60))

        print("\n📥 Fetching RestoreImage records...")
        let restoreImages = try await cloudKitService.queryRecords(recordType: "RestoreImage")

        print("📥 Fetching XcodeVersion records...")
        let xcodeVersions = try await cloudKitService.queryRecords(recordType: "XcodeVersion")

        print("📥 Fetching SwiftVersion records...")
        let swiftVersions = try await cloudKitService.queryRecords(recordType: "SwiftVersion")

        print("\n✅ Exported:")
        print("   • \(restoreImages.count) restore images")
        print("   • \(xcodeVersions.count) Xcode versions")
        print("   • \(swiftVersions.count) Swift versions")

        return ExportResult(
            restoreImages: restoreImages,
            xcodeVersions: xcodeVersions,
            swiftVersions: swiftVersions
        )
    }

    // MARK: - Result Types

    struct SyncResult: Sendable {
        let restoreImagesCount: Int
        let xcodeVersionsCount: Int
        let swiftVersionsCount: Int
    }

    struct ExportResult {
        let restoreImages: [RecordInfo]
        let xcodeVersions: [RecordInfo]
        let swiftVersions: [RecordInfo]
    }
}
