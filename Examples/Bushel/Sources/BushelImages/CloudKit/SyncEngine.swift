import Foundation
import MistKit

/// Orchestrates the complete sync process from data sources to CloudKit
///
/// **Tutorial**: This demonstrates the typical flow for CloudKit data syncing:
/// 1. Fetch data from external sources
/// 2. Transform to CloudKit records
/// 3. Batch upload using MistKit
///
/// Use `--verbose` flag to see detailed MistKit API usage.
struct SyncEngine: Sendable {
    let cloudKitService: BushelCloudKitService
    let pipeline: DataSourcePipeline

    // MARK: - Configuration

    struct SyncOptions: Sendable {
        var dryRun: Bool = false
        var pipelineOptions: DataSourcePipeline.Options = .init()
    }

    // MARK: - Initialization

    init(
        containerIdentifier: String,
        keyID: String,
        privateKeyPath: String,
        configuration: FetchConfiguration = FetchConfiguration.loadFromEnvironment()
    ) throws {
        let service = try BushelCloudKitService(
            containerIdentifier: containerIdentifier,
            keyID: keyID,
            privateKeyPath: privateKeyPath
        )
        self.cloudKitService = service
        self.pipeline = DataSourcePipeline(
            cloudKitService: service,
            configuration: configuration
        )
    }

    // MARK: - Sync Operations

    /// Execute full sync from all data sources to CloudKit
    func sync(options: SyncOptions = SyncOptions()) async throws -> SyncResult {
        print("\n" + String(repeating: "=", count: 60))
        BushelLogger.info("🔄 Starting Bushel CloudKit Sync", subsystem: BushelLogger.sync)
        print(String(repeating: "=", count: 60))

        if options.dryRun {
            BushelLogger.info("🧪 DRY RUN MODE - No changes will be made to CloudKit", subsystem: BushelLogger.sync)
        }

        BushelLogger.explain(
            "This sync demonstrates MistKit's Server-to-Server authentication and bulk record operations",
            subsystem: BushelLogger.sync
        )

        // Step 1: Fetch from all data sources
        print("\n📥 Step 1: Fetching data from external sources...")
        BushelLogger.verbose("Initializing data source pipeline to fetch from ipsw.me, TheAppleWiki, MESU, and other sources", subsystem: BushelLogger.dataSource)

        let fetchResult = try await pipeline.fetch(options: options.pipelineOptions)

        BushelLogger.verbose("Data fetch complete. Beginning deduplication and merge phase.", subsystem: BushelLogger.dataSource)
        BushelLogger.explain(
            "Multiple data sources may have overlapping data. The pipeline deduplicates by version+build number.",
            subsystem: BushelLogger.dataSource
        )

        let stats = SyncResult(
            restoreImagesCount: fetchResult.restoreImages.count,
            xcodeVersionsCount: fetchResult.xcodeVersions.count,
            swiftVersionsCount: fetchResult.swiftVersions.count
        )

        let totalRecords = stats.restoreImagesCount + stats.xcodeVersionsCount + stats.swiftVersionsCount

        print("\n📊 Data Summary:")
        print("   RestoreImages: \(stats.restoreImagesCount)")
        print("   XcodeVersions: \(stats.xcodeVersionsCount)")
        print("   SwiftVersions: \(stats.swiftVersionsCount)")
        print("   ─────────────────────")
        print("   Total: \(totalRecords) records")

        BushelLogger.verbose("Records ready for CloudKit upload: \(totalRecords) total", subsystem: BushelLogger.sync)

        // Step 2: Sync to CloudKit (unless dry run)
        if !options.dryRun {
            print("\n☁️  Step 2: Syncing to CloudKit...")
            BushelLogger.verbose("Using MistKit to batch upload records to CloudKit public database", subsystem: BushelLogger.cloudKit)
            BushelLogger.explain(
                "MistKit handles authentication, batching (200 records/request), and error handling automatically",
                subsystem: BushelLogger.cloudKit
            )

            // Sync in dependency order: SwiftVersion → RestoreImage → XcodeVersion
            // (Prevents broken CKReference relationships)
            try await cloudKitService.syncAllRecords(
                fetchResult.swiftVersions,   // First: no dependencies
                fetchResult.restoreImages,   // Second: no dependencies
                fetchResult.xcodeVersions    // Third: references first two
            )
        } else {
            print("\n⏭️  Step 2: Skipped (dry run)")
            print("   Would sync:")
            print("   • \(stats.restoreImagesCount) restore images")
            print("   • \(stats.xcodeVersionsCount) Xcode versions")
            print("   • \(stats.swiftVersionsCount) Swift versions")
            BushelLogger.verbose("Dry run mode: No CloudKit operations performed", subsystem: BushelLogger.sync)
        }

        print("\n" + String(repeating: "=", count: 60))
        BushelLogger.success("Sync completed successfully!", subsystem: BushelLogger.sync)
        print(String(repeating: "=", count: 60))

        return stats
    }

    /// Delete all records from CloudKit
    func clear() async throws {
        print("\n" + String(repeating: "=", count: 60))
        BushelLogger.info("🗑️  Clearing all CloudKit data", subsystem: BushelLogger.cloudKit)
        print(String(repeating: "=", count: 60))

        try await cloudKitService.deleteAllRecords()

        print("\n" + String(repeating: "=", count: 60))
        BushelLogger.success("Clear completed successfully!", subsystem: BushelLogger.sync)
        print(String(repeating: "=", count: 60))
    }

    /// Export all records from CloudKit to a structured format
    func export() async throws -> ExportResult {
        print("\n" + String(repeating: "=", count: 60))
        BushelLogger.info("📤 Exporting data from CloudKit", subsystem: BushelLogger.cloudKit)
        print(String(repeating: "=", count: 60))

        BushelLogger.explain(
            "Using MistKit's queryRecords() to fetch all records of each type from the public database",
            subsystem: BushelLogger.cloudKit
        )

        print("\n📥 Fetching RestoreImage records...")
        BushelLogger.verbose("Querying CloudKit for recordType: 'RestoreImage' with limit: 1000", subsystem: BushelLogger.cloudKit)
        let restoreImages = try await cloudKitService.queryRecords(recordType: "RestoreImage")
        BushelLogger.verbose("Retrieved \(restoreImages.count) RestoreImage records", subsystem: BushelLogger.cloudKit)

        print("📥 Fetching XcodeVersion records...")
        BushelLogger.verbose("Querying CloudKit for recordType: 'XcodeVersion' with limit: 1000", subsystem: BushelLogger.cloudKit)
        let xcodeVersions = try await cloudKitService.queryRecords(recordType: "XcodeVersion")
        BushelLogger.verbose("Retrieved \(xcodeVersions.count) XcodeVersion records", subsystem: BushelLogger.cloudKit)

        print("📥 Fetching SwiftVersion records...")
        BushelLogger.verbose("Querying CloudKit for recordType: 'SwiftVersion' with limit: 1000", subsystem: BushelLogger.cloudKit)
        let swiftVersions = try await cloudKitService.queryRecords(recordType: "SwiftVersion")
        BushelLogger.verbose("Retrieved \(swiftVersions.count) SwiftVersion records", subsystem: BushelLogger.cloudKit)

        print("\n✅ Exported:")
        print("   • \(restoreImages.count) restore images")
        print("   • \(xcodeVersions.count) Xcode versions")
        print("   • \(swiftVersions.count) Swift versions")

        BushelLogger.explain(
            "MistKit returns RecordInfo structs with record metadata. Use .fields to access CloudKit field values.",
            subsystem: BushelLogger.cloudKit
        )

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
