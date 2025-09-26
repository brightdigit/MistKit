import Crypto
import Foundation
import Testing

@testable import MistKit

extension ServerToServerAuthManagerTests {
  @Suite("Server-to-Server Auth Manager Error Handling")
  /// Test suite for ServerToServerAuthManager error handling functionality
  internal struct ErrorTests {
    // MARK: - Test Data Setup

    private static func generateTestPrivateKeyClosure() -> @Sendable () throws ->
      P256.Signing.PrivateKey
    {
      { P256.Signing.PrivateKey() }
    }

    // MARK: - Error Handling Tests

    /// Tests ServerToServerAuthManager initialization with invalid private key data
    @Test("Initialization with invalid private key data", .enabled(if: Platform.isCryptoAvailable))
    internal func initializationWithInvalidPrivateKeyData() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let invalidKeyData = Data([0, 1, 2, 3, 4, 5])  // Invalid key data

      // This should throw an error
      #expect(throws: CryptoKitError.self) {
        try ServerToServerAuthManager(
          keyID: keyID,
          privateKeyData: invalidKeyData
        )
      }
    }

    /// Tests ServerToServerAuthManager initialization with invalid PEM string
    @Test("Initialization with invalid PEM string", .enabled(if: Platform.isCryptoAvailable))
    internal func initializationWithInvalidPEMString() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }

      let keyID = "test-key-id-12345678"
      let invalidPEM = "-----BEGIN INVALID KEY-----\ninvalid content\n-----END INVALID KEY-----"

      // This should throw a TokenManagerError
      do {
        _ = try ServerToServerAuthManager(
          keyID: keyID,
          pemString: invalidPEM
        )
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(let reason):
          switch reason {
          case .invalidPEMFormat, .privateKeyParseFailed:
            break  // Expected error types
          default:
            Issue.record("Expected PEM format or parse error, got: \(reason)")
          }
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests ServerToServerAuthManager initialization with malformed PEM string
    @Test("Initialization with malformed PEM string", .enabled(if: Platform.isCryptoAvailable))
    internal func initializationWithMalformedPEMString() async throws {
      guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
        Issue.record("ServerToServerAuthManager is not available on this operating system.")
        return
      }
      let keyID = "test-key-id-12345678"
      let malformedPEM = "not a valid PEM string"

      // This should throw a TokenManagerError
      do {
        _ = try ServerToServerAuthManager(
          keyID: keyID,
          pemString: malformedPEM
        )
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(let reason):
          switch reason {
          case .invalidPEMFormat, .privateKeyParseFailed:
            break  // Expected error types
          default:
            Issue.record("Expected PEM format or parse error, got: \(reason)")
          }
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
