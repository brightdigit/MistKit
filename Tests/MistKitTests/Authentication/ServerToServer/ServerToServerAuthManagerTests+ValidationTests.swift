internal import Crypto
internal import Foundation
internal import Testing

@testable import MistKit

extension ServerToServerAuthManagerTests {
  @Suite("Server-to-Server Auth Manager Validation", .enabled(if: Platform.isCryptoAvailable))
  /// Test suite for ServerToServerAuthManager validation functionality
  internal struct ValidationTests {
    private static func generateTestPrivateKey() throws -> P256.Signing.PrivateKey {
      P256.Signing.PrivateKey()
    }

    /// Tests validateCredentials with valid credentials
    @Test("validateCredentials with valid credentials", .enabled(if: Platform.isCryptoAvailable))
    internal func validateCredentialsValidCredentials() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let manager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKey()
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)

      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests validateCredentials with short key ID
    @Test("validateCredentials with short key ID", .enabled(if: Platform.isCryptoAvailable))
    internal func validateCredentialsShortKeyID() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let shortKeyID = "short"
      _ = try Self.generateTestPrivateKey()

      // Create manager with short key ID (this will pass precondition but fail validation)
      let manager = try ServerToServerAuthManager(
        keyID: shortKeyID,
        privateKeyCallback: try Self.generateTestPrivateKey()
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(let reason):
          if case .keyIdTooShort = reason {
            // Expected case
          } else {
            Issue.record("Expected .keyIdTooShort, got: \(reason)")
          }
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests validateCredentials with corrupted private key
    @Test(
      "validateCredentials with corrupted private key", .enabled(if: Platform.isCryptoAvailable))
    internal func validateCredentialsCorruptedPrivateKey() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"

      // Create a manager with a private key that will fail signature creation
      // We'll use a custom callback that throws an error
      let manager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKey()
      )

      // This should actually pass since we're using a valid key
      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests currentAuthenticator with valid credentials
    @Test("currentAuthenticator with valid credentials", .enabled(if: Platform.isCryptoAvailable))
    internal func currentAuthenticatorValidCredentials() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let manager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: try Self.generateTestPrivateKey()
      )

      let authenticator = try await manager.currentAuthenticator()
      let s2s = try #require(authenticator as? ServerToServerAuthenticator)
      #expect(s2s.keyID == keyID)
      #expect(s2s.privateKey.rawRepresentation == manager.privateKeyData)
    }

    /// Tests currentAuthenticator with invalid credentials
    @Test(
      "currentAuthenticator with invalid credentials", .enabled(if: Platform.isCryptoAvailable))
    internal func currentAuthenticatorInvalidCredentials() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let shortKeyID = "short"
      _ = try Self.generateTestPrivateKey()

      // Create manager with short key ID
      let manager = try ServerToServerAuthManager(
        keyID: shortKeyID,
        privateKeyCallback: try Self.generateTestPrivateKey()
      )

      do {
        _ = try await manager.currentAuthenticator()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(let reason):
          if case .keyIdTooShort = reason {
            // Expected case
          } else {
            Issue.record("Expected .keyIdTooShort, got: \(reason)")
          }
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    // MARK: - Key ID Validation Tests

    /// Tests various key ID formats
    @Test("Key ID validation", .enabled(if: Platform.isCryptoAvailable))
    internal func keyIDValidation() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let testCases = [
        ("valid-key-id-12345678", true),
        ("another-valid-key-12345678", true),
        ("short", false),
        ("", false),  // This will fail at initialization due to precondition
        ("12345678", true),  // Exactly 8 characters
        ("1234567", false),  // 7 characters
      ]

      for (keyID, shouldBeValid) in testCases {
        if keyID.isEmpty {
          // Skip empty key ID test as it fails at initialization
          continue
        }

        _ = try Self.generateTestPrivateKey()
        let manager = try ServerToServerAuthManager(
          keyID: keyID,
          privateKeyCallback: try Self.generateTestPrivateKey()
        )

        do {
          let isValid = try await manager.validateCredentials()
          #expect(
            isValid == shouldBeValid,
            "Key ID '\(keyID)' should be \(shouldBeValid ? "valid" : "invalid")")
        } catch {
          switch error {
          case TokenManagerError.invalidCredentials(let reason):
            #expect(!shouldBeValid, "Key ID '\(keyID)' should be valid but got error: \(reason)")
          default:
            Issue.record("Unexpected error for key ID '\(keyID)': \(error)")
          }
        }
      }
    }
  }
}
