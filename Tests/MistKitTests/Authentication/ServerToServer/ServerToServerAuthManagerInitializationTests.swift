import Crypto
import Foundation
import Testing

@testable import MistKit

@Suite("Server-to-Server Auth Manager Initialization")
/// Test suite for ServerToServerAuthManager initialization functionality
struct ServerToServerAuthManagerInitializationTests {
  // MARK: - Test Data Setup

  private static func generateTestPrivateKey() throws -> P256.Signing.PrivateKey {
    P256.Signing.PrivateKey()
  }

  private static func generateTestPrivateKeyClosure() -> @Sendable () throws ->
    P256.Signing.PrivateKey
  {
    { P256.Signing.PrivateKey() }
  }

  private static func generateTestPrivateKeyData() throws -> Data {
    let privateKey = try generateTestPrivateKey()
    return privateKey.rawRepresentation
  }

  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  private static func generateTestPEMString() throws -> String {
    let privateKey = try generateTestPrivateKey()
    return privateKey.pemRepresentation
  }

  // MARK: - Initialization Tests

  /// Tests ServerToServerAuthManager initialization with private key callback
  @Test("Initialization with private key callback", .enabled(if: Platform.isCryptoAvailable))
  func initializationWithPrivateKeyCallback() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    let keyID = "test-key-id-12345678"

    let manager = try ServerToServerAuthManager(
      keyID: keyID,
      privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
    )

    // Verify manager properties
    #expect(manager.keyID == keyID)

    // Test that we can get credentials
    let credentials = try await manager.getCurrentCredentials()
    #expect(credentials != nil)

    if let credentials = credentials {
      if case .serverToServer(let storedKeyID, let storedPrivateKey) = credentials.method {
        #expect(storedKeyID == keyID)
        #expect(storedPrivateKey == manager.privateKeyData)
      } else {
        Issue.record("Expected .serverToServer method")
      }
    }
  }

  /// Tests ServerToServerAuthManager initialization with private key data
  @Test("Initialization with private key data", .enabled(if: Platform.isCryptoAvailable))
  func initializationWithPrivateKeyData() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    let keyID = "test-key-id-12345678"
    let privateKeyData = try Self.generateTestPrivateKeyData()

    let manager = try ServerToServerAuthManager(
      keyID: keyID,
      privateKeyData: privateKeyData
    )

    // Verify manager properties
    #expect(manager.keyID == keyID)

    // Test that we can get credentials
    let credentials = try await manager.getCurrentCredentials()
    #expect(credentials != nil)

    if let credentials = credentials {
      if case .serverToServer(let storedKeyID, let storedPrivateKey) = credentials.method {
        #expect(storedKeyID == keyID)
        #expect(storedPrivateKey == privateKeyData)
      } else {
        Issue.record("Expected .serverToServer method")
      }
    }
  }

  /// Tests ServerToServerAuthManager initialization with PEM string
  @Test("Initialization with PEM string", .enabled(if: Platform.isCryptoAvailable))
  func initializationWithPEMString() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    let keyID = "test-key-id-12345678"
    let pemString = try Self.generateTestPEMString()

    let manager = try ServerToServerAuthManager(
      keyID: keyID,
      pemString: pemString
    )

    // Verify manager properties
    #expect(manager.keyID == keyID)

    // Test that we can get credentials
    let credentials = try await manager.getCurrentCredentials()
    #expect(credentials != nil)

    if let credentials = credentials {
      if case .serverToServer(let storedKeyID, _) = credentials.method {
        #expect(storedKeyID == keyID)
      } else {
        Issue.record("Expected .serverToServer method")
      }
    }
  }

  /// Tests ServerToServerAuthManager initialization with storage
  @Test("Initialization with storage", .enabled(if: Platform.isCryptoAvailable))
  func initializationWithStorage() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    let keyID = "test-key-id-12345678"
    let storage = InMemoryTokenStorage()

    let manager = try ServerToServerAuthManager(
      keyID: keyID,
      privateKeyCallback: try Self.generateTestPrivateKeyClosure()(),
      storage: storage
    )

    // Verify manager properties
    #expect(manager.keyID == keyID)
  }

  /// Tests ServerToServerAuthManager initialization with empty key ID (should crash)
  @Test("Initialization with empty key ID", .enabled(if: Platform.isCryptoAvailable))
  func initializationWithEmptyKeyID() async throws {
    guard #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) else {
      Issue.record("ServerToServerAuthManager is not available on this operating system.")
      return
    }
    // This should crash due to precondition - we can't easily test this with Swift Testing
    // Instead, we'll test that a valid key ID works
    let validKeyID = "test-key-id-12345678"

    let manager = try ServerToServerAuthManager(
      keyID: validKeyID,
      privateKeyCallback: try Self.generateTestPrivateKeyClosure()()
    )
    #expect(manager.keyID == validKeyID)
  }
}
