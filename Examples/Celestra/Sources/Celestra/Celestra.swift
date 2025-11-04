import ArgumentParser
import Foundation
import MistKit

@main
struct Celestra: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "celestra",
        abstract: "RSS reader that syncs to CloudKit public database",
        discussion: """
            Celestra demonstrates MistKit's query filtering and sorting features by managing \
            RSS feeds in CloudKit's public database.
            """,
        subcommands: [
            AddFeedCommand.self,
            UpdateCommand.self,
            ClearCommand.self
        ]
    )
}

// MARK: - Shared Configuration

/// Shared configuration helper for creating CloudKit service
enum CelestraConfig {
    /// Create CloudKit service from environment variables
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    static func createCloudKitService() throws -> CloudKitService {
        // Validate required environment variables
        guard let containerID = ProcessInfo.processInfo.environment["CLOUDKIT_CONTAINER_ID"] else {
            throw ValidationError("CLOUDKIT_CONTAINER_ID environment variable required")
        }

        guard let keyID = ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] else {
            throw ValidationError("CLOUDKIT_KEY_ID environment variable required")
        }

        guard let privateKeyPath = ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"]
        else {
            throw ValidationError("CLOUDKIT_PRIVATE_KEY_PATH environment variable required")
        }

        // Read private key from file
        let privateKeyPEM = try String(contentsOfFile: privateKeyPath, encoding: .utf8)

        // Determine environment (development or production)
        let environment: MistKit.Environment =
            ProcessInfo.processInfo.environment["CLOUDKIT_ENVIRONMENT"] == "production"
            ? .production
            : .development

        // Create token manager for server-to-server authentication
        let tokenManager = try ServerToServerAuthManager(
            keyID: keyID,
            pemString: privateKeyPEM
        )

        // Create and return CloudKit service
        return try CloudKitService(
            containerIdentifier: containerID,
            tokenManager: tokenManager,
            environment: environment,
            database: .public
        )
    }
}
