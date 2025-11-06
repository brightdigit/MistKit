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
struct BushelCloudKitService: Sendable {
    let service: CloudKitService

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
}
