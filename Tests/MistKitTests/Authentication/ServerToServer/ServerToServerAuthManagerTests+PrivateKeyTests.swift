import Crypto
import Foundation
import Testing

@testable import MistKit

extension ServerToServerAuthManagerTests {
  /// Private key validation tests for ServerToServerAuthManager
  @Suite("Private Key Tests", .enabled(if: Platform.isCryptoAvailable))
  internal struct PrivateKeyTests {
    private static func generateTestPrivateKeyClosure()
      -> @Sendable () throws ->
      P256.Signing.PrivateKey
    {
      { P256.Signing.PrivateKey() }
    }

    // MARK: - Private Key Validation Tests

    /// Tests that private key can be used for signing
    @Test("Private key signing validation", .enabled(if: Platform.isCryptoAvailable))
    internal func privateKeySigningValidation() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let manager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
      )

      // Validate credentials (this internally tests signing)
      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests that different private keys produce different signatures
    @Test(
      "Different private keys produce different signatures",
      .enabled(if: Platform.isCryptoAvailable))
    internal func differentPrivateKeysProduceDifferentSignatures() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"

      let manager1 = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
      )

      let manager2 = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
      )

      // Both should be valid
      let isValid1 = try await manager1.validateCredentials()
      let isValid2 = try await manager2.validateCredentials()
      #expect(isValid1 == true)
      #expect(isValid2 == true)

      // But they should have different private keys
      let credentials1 = try await manager1.getCurrentCredentials()
      let credentials2 = try await manager2.getCurrentCredentials()

      #expect(credentials1 != nil)
      #expect(credentials2 != nil)

      if let cred1 = credentials1, let cred2 = credentials2 {
        if case .serverToServer(let keyID1, let privateKeyData1) = cred1.method,
          case .serverToServer(let keyID2, let privateKeyData2) = cred2.method
        {
          #expect(keyID1 == keyID2)  // Same key ID
          #expect(privateKeyData1 != privateKeyData2)  // Different private keys
        } else {
          Issue.record("Expected serverToServer method")
        }
      }
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that ServerToServerAuthManager can be used across async boundaries
    @Test("ServerToServerAuthManager sendable compliance", .enabled(if: Platform.isCryptoAvailable))
    internal func serverToServerAuthManagerSendableCompliance() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let manager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
      )

      // Test concurrent access patterns
      async let task1 = manager.validateManager()
      async let task2 = manager.getCredentialsFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
