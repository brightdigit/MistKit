#!/usr/bin/env swift

import Foundation
import MistKit
import Crypto

/// Example demonstrating server-to-server authentication with MistKit
/// This example shows how to set up and use CloudKit Web Services with ECDSA P-256 signing

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
@main
struct AuthTransitionExample {
    static func main() async {
        print("🔐 MistKit Server-to-Server Authentication Example")
        print(String(repeating: "=", count: 60))
        print("ℹ️  Important: Server-to-server authentication only supports public database")
        print("ℹ️  Setup required: Register public key in CloudKit Dashboard first")
        print(String(repeating: "-", count: 60))

        do {
            // Example 1: Using a PEM file
            await demonstratePEMFileAuth()

            print()

            // Example 2: Using generated test keys
            await demonstrateGeneratedKeyAuth()

        } catch {
            print("❌ Error: \(error.localizedDescription)")
        }
    }

    /// Demonstrates authentication using a PEM file
    static func demonstratePEMFileAuth() async {
        print("📁 Example 1: PEM File Authentication")
        print("-" * 40)

        // Example paths - update these with your actual values
        let keyID = "your-key-id-here"
        let pemFilePath = "/path/to/your/private-key.pem"

        do {
            // Read PEM file
            let pemString = try String(contentsOfFile: pemFilePath)

            // Create server-to-server auth manager
            let authManager = try ServerToServerAuthManager(
                keyID: keyID,
                pemString: pemString
            )

            // Validate credentials
            let isValid = try await authManager.validateCredentials()
            print("✅ Credentials valid: \(isValid)")

            // Get credentials for use with MistKit client
            if let credentials = try await authManager.getCurrentCredentials() {
                print("✅ Server-to-server credentials obtained")

                // Create MistKit configuration for server-to-server (public database only)
                let config = MistKitConfiguration.serverToServer(
                    container: "iCloud.com.example.MyApp",
                    environment: .development
                )

                // Create authenticated client
                let client = MistKitClient(
                    configuration: config,
                    tokenManager: authManager
                )

                print("✅ MistKit client configured with server-to-server authentication (public database)")
                print("ℹ️  Note: Server-to-server authentication only supports the public database")

                // Example: Query public records (typical server-to-server use case)
                // Note: This may fail if the CloudKit container isn't properly configured
                // or if there are no public records, but it demonstrates the auth flow
                print("🌐 Testing public record access with CloudKit...")
                // Example of what you might do:
                // let publicRecords = try await client.queryRecords(recordType: "PublicData", limit: 10)

            } else {
                print("❌ Failed to obtain credentials")
            }

        } catch {
            print("❌ PEM file authentication failed: \(error.localizedDescription)")
        }
    }

    /// Demonstrates authentication using generated test keys
    static func demonstrateGeneratedKeyAuth() async {
        print("🔑 Example 2: Generated Key Authentication")
        print("-" * 40)

        do {
            // Generate test keys
            let privateKey = P256.Signing.PrivateKey()
            let testKeyID = generateTestKeyID()

            print("🔑 Generated test key ID: \(testKeyID)")
            print("🔑 Generated private key (first 50 chars): \(String(privateKey.pemRepresentation.prefix(50)))...")

            // Create auth manager with generated key
            let authManager = ServerToServerAuthManager(
                keyID: testKeyID,
                privateKey: privateKey
            )

            // Validate credentials
            let isValid = try await authManager.validateCredentials()
            print("✅ Generated credentials valid: \(isValid)")

            // Demonstrate signing a request
            let testSignature = try authManager.signRequest(
                requestBody: "test request".data(using: .utf8),
                webServiceURL: "https://api.apple-cloudkit.com/database/1/iCloud.com.example.MyApp/development/public/records/query"
            )

            print("✅ Test request signed successfully")
            print("   Key ID: \(testSignature.keyID)")
            print("   Date: \(testSignature.date)")
            print("   Signature: \(String(testSignature.signature.prefix(32)))...")

        } catch {
            print("❌ Generated key authentication failed: \(error.localizedDescription)")
        }
    }

    /// Generates a test key ID
    static func generateTestKeyID() -> String {
        let characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<32).compactMap { _ in characters.randomElement() })
    }
}

/// Platform availability check
func checkPlatformSupport() {
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
        print("✅ Platform supports server-to-server authentication")
    } else {
        print("❌ Platform does not support server-to-server authentication")
        print("   Requires: macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+")
    }
}

// String multiplication operator for convenience
infix operator *: MultiplicationPrecedence
extension String {
    static func *(left: String, right: Int) -> String {
        return String(repeating: left, count: right)
    }
}