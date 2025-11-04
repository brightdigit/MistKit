import ArgumentParser
import Foundation

struct SyncCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "sync",
        abstract: "Fetch version data and sync to CloudKit",
        discussion: """
        Fetches macOS restore images, Xcode versions, and Swift versions from
        external data sources and syncs them to the CloudKit public database.

        Data sources:
        • RestoreImage: ipsw.me, Mr. Macintosh, Apple MESU
        • XcodeVersion: xcodereleases.com
        • SwiftVersion: swiftversion.net
        """
    )

    // MARK: - Required Options

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

    @Option(name: .shortAndLong, help: "CloudKit API token (or set CLOUDKIT_API_TOKEN)")
    var apiToken: String = ""

    // MARK: - Sync Options

    @Flag(name: .long, help: "Perform a dry run without syncing to CloudKit")
    var dryRun: Bool = false

    @Flag(name: .long, help: "Sync only restore images")
    var restoreImagesOnly: Bool = false

    @Flag(name: .long, help: "Sync only Xcode versions")
    var xcodeOnly: Bool = false

    @Flag(name: .long, help: "Sync only Swift versions")
    var swiftOnly: Bool = false

    @Flag(name: .long, help: "Exclude beta/RC releases")
    var noBetas: Bool = false

    // MARK: - Execution

    mutating func run() async throws {
        // Get API token from environment if not provided
        let resolvedApiToken = apiToken.isEmpty ?
            ProcessInfo.processInfo.environment["CLOUDKIT_API_TOKEN"] ?? "" :
            apiToken

        guard !resolvedApiToken.isEmpty else {
            print("❌ Error: CloudKit API token is required")
            print("   Provide via --api-token or set CLOUDKIT_API_TOKEN environment variable")
            print("   Get your API token from: https://icloud.developer.apple.com/dashboard/")
            throw ExitCode.failure
        }

        // Determine what to sync
        let options = buildSyncOptions()

        // Create sync engine
        let syncEngine = try SyncEngine(
            containerIdentifier: containerIdentifier,
            apiToken: resolvedApiToken
        )

        // Execute sync
        do {
            let result = try await syncEngine.sync(options: options)
            printSuccess(result)
        } catch {
            printError(error)
            throw ExitCode.failure
        }
    }

    // MARK: - Private Helpers

    private func buildSyncOptions() -> SyncEngine.SyncOptions {
        var pipelineOptions = DataSourcePipeline.Options()

        // Apply filters based on flags
        if restoreImagesOnly {
            pipelineOptions.includeXcodeVersions = false
            pipelineOptions.includeSwiftVersions = false
        } else if xcodeOnly {
            pipelineOptions.includeRestoreImages = false
            pipelineOptions.includeSwiftVersions = false
        } else if swiftOnly {
            pipelineOptions.includeRestoreImages = false
            pipelineOptions.includeXcodeVersions = false
        }

        if noBetas {
            pipelineOptions.includeBetaReleases = false
        }

        return SyncEngine.SyncOptions(
            dryRun: dryRun,
            pipelineOptions: pipelineOptions
        )
    }

    private func printSuccess(_ result: SyncEngine.SyncResult) {
        print("\n" + String(repeating: "=", count: 60))
        print("✅ Sync Summary")
        print(String(repeating: "=", count: 60))
        print("Restore Images: \(result.restoreImagesCount)")
        print("Xcode Versions: \(result.xcodeVersionsCount)")
        print("Swift Versions: \(result.swiftVersionsCount)")
        print(String(repeating: "=", count: 60))
        print("\n💡 Next: Use 'bushel-images export' to view the synced data")
    }

    private func printError(_ error: Error) {
        print("\n❌ Sync failed: \(error.localizedDescription)")
        print("\n💡 Troubleshooting:")
        print("   • Verify your API token is valid")
        print("   • Check your internet connection")
        print("   • Ensure the CloudKit container exists")
        print("   • Verify external data sources are accessible")
    }
}
