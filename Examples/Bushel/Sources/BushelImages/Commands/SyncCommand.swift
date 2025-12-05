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
        • RestoreImage: ipsw.me, TheAppleWiki.com, Mr. Macintosh, Apple MESU
        • XcodeVersion: xcodereleases.com
        • SwiftVersion: swiftversion.net
        """
    )

    // MARK: - Required Options

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

    @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
    var keyID: String = ""

    @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
    var keyFile: String = ""

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

    @Flag(name: .long, help: "Exclude TheAppleWiki.com as data source")
    var noAppleWiki: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose logging to see detailed CloudKit operations and learn MistKit usage patterns")
    var verbose: Bool = false

    @Flag(name: .long, help: "Disable log redaction for debugging (shows actual CloudKit field names in errors)")
    var noRedaction: Bool = false

    // MARK: - Throttling Options

    @Flag(name: .long, help: "Force fetch from all sources, ignoring minimum fetch intervals")
    var force: Bool = false

    @Option(name: .long, help: "Minimum interval between fetches in seconds (overrides default intervals)")
    var minInterval: Int?

    @Option(name: .long, help: "Fetch from only this specific source (e.g., 'appledb.dev', 'ipsw.me')")
    var source: String?

    // MARK: - Execution

    mutating func run() async throws {
        // Enable verbose logging if requested
        BushelLogger.isVerbose = verbose

        // Disable log redaction for debugging if requested
        if noRedaction {
            setenv("MISTKIT_DISABLE_LOG_REDACTION", "1", 1)
        }

        // Get Server-to-Server credentials from environment if not provided
        let resolvedKeyID = keyID.isEmpty ?
            ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] ?? "" :
            keyID

        let resolvedKeyFile = keyFile.isEmpty ?
            ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"] ?? "" :
            keyFile

        guard !resolvedKeyID.isEmpty && !resolvedKeyFile.isEmpty else {
            print("❌ Error: CloudKit Server-to-Server Key credentials are required")
            print("")
            print("   Provide via command-line flags:")
            print("     --key-id YOUR_KEY_ID --key-file ./private-key.pem")
            print("")
            print("   Or set environment variables:")
            print("     export CLOUDKIT_KEY_ID=\"YOUR_KEY_ID\"")
            print("     export CLOUDKIT_PRIVATE_KEY_PATH=\"./private-key.pem\"")
            print("")
            print("   Get your Server-to-Server Key from:")
            print("   https://icloud.developer.apple.com/dashboard/")
            print("   Navigate to: API Access → Server-to-Server Keys")
            print("")
            print("   Important:")
            print("   • Download and save the private key .pem file securely")
            print("   • Never commit .pem files to version control!")
            print("")
            throw ExitCode.failure
        }

        // Determine what to sync
        let options = buildSyncOptions()

        // Build fetch configuration
        let configuration = buildFetchConfiguration()

        // Create sync engine
        let syncEngine = try SyncEngine(
            containerIdentifier: containerIdentifier,
            keyID: resolvedKeyID,
            privateKeyPath: resolvedKeyFile,
            configuration: configuration
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

        if noAppleWiki {
            pipelineOptions.includeTheAppleWiki = false
        }

        // Apply throttling options
        pipelineOptions.force = force
        pipelineOptions.specificSource = source

        return SyncEngine.SyncOptions(
            dryRun: dryRun,
            pipelineOptions: pipelineOptions
        )
    }

    private func buildFetchConfiguration() -> FetchConfiguration {
        // Load configuration from environment
        var config = FetchConfiguration.loadFromEnvironment()

        // Override with command-line flag if provided
        if let interval = minInterval {
            config = FetchConfiguration(
                globalMinimumFetchInterval: TimeInterval(interval),
                perSourceIntervals: config.perSourceIntervals,
                useDefaults: true
            )
        }

        return config
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
