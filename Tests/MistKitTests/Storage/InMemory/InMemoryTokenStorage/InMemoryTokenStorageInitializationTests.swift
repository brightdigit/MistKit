import Foundation
import Testing

@testable import MistKit

@Suite("In-Memory Token Storage Initialization")
/// Test suite for InMemoryTokenStorage initialization and basic storage functionality
struct InMemoryTokenStorageInitializationTests {
  // MARK: - Test Data Setup

  private static let testAPIToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
  private static let testWebAuthToken = "user123_web_auth_token_abcdef"

  // MARK: - Initialization Tests

  /// Tests InMemoryTokenStorage initialization
  @Test("InMemoryTokenStorage initialization")
  func initialization() {
    let storage = InMemoryTokenStorage()
    // Storage should be created successfully
    _ = storage
  }

  // MARK: - Token Storage Tests

  /// Tests storing API token
  @Test("Store API token")
  func storeAPIToken() async throws {
    let storage = InMemoryTokenStorage()
    let credentials = TokenCredentials.apiToken(Self.testAPIToken)

    try await storage.store(credentials, identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved != nil)

    if let retrieved = retrieved {
      if case .apiToken(let token) = retrieved.method {
        #expect(token == Self.testAPIToken)
      } else {
        Issue.record("Expected .apiToken method")
      }
    }
  }

  /// Tests storing web auth token
  @Test("Store web auth token")
  func storeWebAuthToken() async throws {
    let storage = InMemoryTokenStorage()
    let credentials = TokenCredentials.webAuthToken(
      apiToken: Self.testAPIToken,
      webToken: Self.testWebAuthToken
    )

    try await storage.store(credentials, identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved != nil)

    if let retrieved = retrieved {
      if case .webAuthToken(let api, let web) = retrieved.method {
        #expect(api == Self.testAPIToken)
        #expect(web == Self.testWebAuthToken)
      } else {
        Issue.record("Expected .webAuthToken method")
      }
    }
  }

  /// Tests storing server-to-server credentials
  @Test("Store server-to-server credentials")
  func storeServerToServerCredentials() async throws {
    let storage = InMemoryTokenStorage()
    let keyID = "test-key-id-12345678"
    let privateKeyData = Data([1, 2, 3, 4, 5])
    let credentials = TokenCredentials.serverToServer(
      keyID: keyID,
      privateKey: privateKeyData
    )

    try await storage.store(credentials, identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved != nil)

    if let retrieved = retrieved {
      if case .serverToServer(let storedKeyID, let storedPrivateKey) = retrieved.method {
        #expect(storedKeyID == keyID)
        #expect(storedPrivateKey == privateKeyData)
      } else {
        Issue.record("Expected .serverToServer method")
      }
    }
  }

  /// Tests storing credentials with metadata
  @Test("Store credentials with metadata")
  func storeCredentialsWithMetadata() async throws {
    let storage = InMemoryTokenStorage()
    let metadata = ["created": "2025-01-01", "environment": "test"]
    let credentials = TokenCredentials(
      method: .apiToken(Self.testAPIToken),
      metadata: metadata
    )

    try await storage.store(credentials, identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved != nil)

    if let retrieved = retrieved {
      #expect(retrieved.metadata["created"] == "2025-01-01")
      #expect(retrieved.metadata["environment"] == "test")
    }
  }
}
