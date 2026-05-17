import Crypto
import Foundation
import Testing

@testable import MistKit

extension ServerToServerAuthManagerTests {
  /// Private key validation tests for ServerToServerAuthManager
  @Suite("Private Key", .enabled(if: Platform.isCryptoAvailable))
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
      let auth1 = try #require(
        try await manager1.currentAuthenticator() as? ServerToServerAuthenticator
      )
      let auth2 = try #require(
        try await manager2.currentAuthenticator() as? ServerToServerAuthenticator
      )

      #expect(auth1.keyID == auth2.keyID)
      #expect(auth1.privateKey.rawRepresentation != auth2.privateKey.rawRepresentation)
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
      async let task2 = manager.authenticatorFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
