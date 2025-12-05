import ArgumentParser
import Foundation
import MistKit

struct ExportCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "export",
        abstract: "Export CloudKit data to JSON",
        discussion: """
        Queries the CloudKit public database and exports all version records
        to JSON format for analysis or backup.
        """
    )

    // MARK: - Required Options

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

    @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
    var keyID: String = ""

    @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
    var keyFile: String = ""

    // MARK: - Export Options

    @Option(name: .shortAndLong, help: "Output file path (default: stdout)")
    var output: String?

    @Flag(name: .long, help: "Pretty-print JSON output")
    var pretty: Bool = false

    @Flag(name: .long, help: "Export only signed restore images")
    var signedOnly: Bool = false

    @Flag(name: .long, help: "Exclude beta/RC releases")
    var noBetas: Bool = false

    @Flag(name: .shortAndLong, help: "Enable verbose logging to see detailed CloudKit operations and learn MistKit usage patterns")
    var verbose: Bool = false

    // MARK: - Execution

    mutating func run() async throws {
        // Enable verbose logging if requested
        BushelLogger.isVerbose = verbose

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

        // Create sync engine
        let syncEngine = try SyncEngine(
            containerIdentifier: containerIdentifier,
            keyID: resolvedKeyID,
            privateKeyPath: resolvedKeyFile
        )

        // Execute export
        do {
            let result = try await syncEngine.export()
            let filtered = applyFilters(to: result)
            let json = try encodeToJSON(filtered)

            if let outputPath = output {
                try writeToFile(json, at: outputPath)
                print("✅ Exported to: \(outputPath)")
            } else {
                print(json)
            }
        } catch {
            printError(error)
            throw ExitCode.failure
        }
    }

    // MARK: - Private Helpers

    private func applyFilters(to result: SyncEngine.ExportResult) -> SyncEngine.ExportResult {
        var restoreImages = result.restoreImages
        var xcodeVersions = result.xcodeVersions
        var swiftVersions = result.swiftVersions

        // Filter signed-only restore images
        if signedOnly {
            restoreImages = restoreImages.filter { record in
                if case .int64(let isSigned) = record.fields["isSigned"] {
                    return isSigned != 0
                }
                return false
            }
        }

        // Filter out betas
        if noBetas {
            restoreImages = restoreImages.filter { record in
                if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
                    return isPrerelease == 0
                }
                return true
            }

            xcodeVersions = xcodeVersions.filter { record in
                if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
                    return isPrerelease == 0
                }
                return true
            }

            swiftVersions = swiftVersions.filter { record in
                if case .int64(let isPrerelease) = record.fields["isPrerelease"] {
                    return isPrerelease == 0
                }
                return true
            }
        }

        return SyncEngine.ExportResult(
            restoreImages: restoreImages,
            xcodeVersions: xcodeVersions,
            swiftVersions: swiftVersions
        )
    }

    private func encodeToJSON(_ result: SyncEngine.ExportResult) throws -> String {
        let export = ExportData(
            restoreImages: result.restoreImages.map(RecordExport.init),
            xcodeVersions: result.xcodeVersions.map(RecordExport.init),
            swiftVersions: result.swiftVersions.map(RecordExport.init)
        )

        let encoder = JSONEncoder()
        if pretty {
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        }

        let data = try encoder.encode(export)
        guard let json = String(data: data, encoding: .utf8) else {
            throw ExportError.encodingFailed
        }

        return json
    }

    private func writeToFile(_ content: String, at path: String) throws {
        try content.write(toFile: path, atomically: true, encoding: .utf8)
    }

    private func printError(_ error: Error) {
        print("\n❌ Export failed: \(error.localizedDescription)")
        print("\n💡 Troubleshooting:")
        print("   • Verify your API token is valid")
        print("   • Check your internet connection")
        print("   • Ensure data has been synced to CloudKit")
        print("   • Run 'bushel-images sync' first if needed")
    }

    // MARK: - Export Types

    struct ExportData: Codable {
        let restoreImages: [RecordExport]
        let xcodeVersions: [RecordExport]
        let swiftVersions: [RecordExport]
    }

    struct RecordExport: Codable {
        let recordName: String
        let recordType: String
        let fields: [String: String]

        init(from recordInfo: RecordInfo) {
            self.recordName = recordInfo.recordName
            self.recordType = recordInfo.recordType
            self.fields = recordInfo.fields.mapValues { fieldValue in
                String(describing: fieldValue)
            }
        }
    }

    enum ExportError: Error {
        case encodingFailed
    }
}
