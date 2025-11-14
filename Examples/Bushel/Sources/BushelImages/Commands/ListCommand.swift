//  ListCommand.swift
//  Created by Claude Code

import ArgumentParser
import Foundation
import MistKit

struct ListCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "list",
        abstract: "List CloudKit records",
        discussion: """
            Displays all records stored in CloudKit across different record types.

            By default, lists all record types. Use flags to show specific types only.
            """
    )

    // MARK: - Required Options

    @Option(name: .shortAndLong, help: "CloudKit container identifier")
    var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

    @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
    var keyID: String = ""

    @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
    var keyFile: String = ""

    // MARK: - Filter Options

    @Flag(name: .long, help: "List only restore images")
    var restoreImages: Bool = false

    @Flag(name: .long, help: "List only Xcode versions")
    var xcodeVersions: Bool = false

    @Flag(name: .long, help: "List only Swift versions")
    var swiftVersions: Bool = false

    // MARK: - Display Options

    @Flag(name: .long, help: "Disable log redaction for debugging")
    var noRedaction: Bool = false

    // MARK: - Execution

    mutating func run() async throws {
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

        guard !resolvedKeyID.isEmpty, !resolvedKeyFile.isEmpty else {
            print("❌ Error: CloudKit Server-to-Server Key credentials are required")
            print("")
            print("   Provide via command-line flags:")
            print("     --key-id YOUR_KEY_ID --key-file ./private-key.pem")
            print("")
            print("   Or set environment variables:")
            print("     export CLOUDKIT_KEY_ID=\"YOUR_KEY_ID\"")
            print("     export CLOUDKIT_PRIVATE_KEY_PATH=\"./private-key.pem\"")
            print("")
            throw ExitCode.failure
        }

        // Create CloudKit service
        let cloudKitService = try BushelCloudKitService(
            containerIdentifier: containerIdentifier,
            keyID: resolvedKeyID,
            privateKeyPath: resolvedKeyFile
        )

        // Determine what to list based on flags
        let listAll = !restoreImages && !xcodeVersions && !swiftVersions

        if listAll {
            try await cloudKitService.listAllRecords()
        } else {
            if restoreImages {
                try await cloudKitService.list(RestoreImageRecord.self)
            }
            if xcodeVersions {
                try await cloudKitService.list(XcodeVersionRecord.self)
            }
            if swiftVersions {
                try await cloudKitService.list(SwiftVersionRecord.self)
            }
        }
    }
}
