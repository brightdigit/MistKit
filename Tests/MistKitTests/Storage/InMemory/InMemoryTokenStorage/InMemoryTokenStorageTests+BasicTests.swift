import Foundation
import Testing

@testable import MistKit

@Suite("In-Memory Token Storage")
enum InMemoryTokenStorageTests {}

extension InMemoryTokenStorageTests {
  /// Basic functionality tests for InMemoryTokenStorage
  @Suite("Basic Tests")
  struct BasicTests {
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

    // MARK: - Token Retrieval Tests

    /// Tests retrieving stored token
    @Test("Retrieve stored token")
    func retrieveStoredToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)

      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved != nil)
      #expect(retrieved == credentials)
    }

    /// Tests retrieving non-existent token
    @Test("Retrieve non-existent token")
    func retrieveNonExistentToken() async throws {
      let storage = InMemoryTokenStorage()

      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved == nil)
    }

    /// Tests retrieving token after clearing storage
    @Test("Retrieve token after clearing storage")
    func retrieveTokenAfterClearingStorage() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)
      await storage.clear()

      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved == nil)
    }

    // MARK: - Token Removal Tests

    /// Tests removing stored token
    @Test("Remove stored token")
    func removeStoredToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      #expect(retrievedAfter == nil)
    }

    /// Tests removing non-existent token
    @Test("Remove non-existent token")
    func removeNonExistentToken() async throws {
      let storage = InMemoryTokenStorage()

      // Should not throw or crash
      try await storage.remove(identifier: nil)

      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved == nil)
    }

    // MARK: - Token Replacement Tests

    /// Tests replacing stored token with new token
    @Test("Replace stored token with new token")
    func replaceStoredTokenWithNewToken() async throws {
      let storage = InMemoryTokenStorage()
      let originalCredentials = TokenCredentials.apiToken(Self.testAPIToken)
      let newCredentials = TokenCredentials.webAuthToken(
        apiToken: Self.testAPIToken,
        webToken: Self.testWebAuthToken
      )

      try await storage.store(originalCredentials, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.store(newCredentials, identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      #expect(retrievedAfter != nil)
      #expect(retrievedAfter == newCredentials)
      #expect(retrievedAfter != originalCredentials)
    }

    /// Tests replacing stored token with same token
    @Test("Replace stored token with same token")
    func replaceStoredTokenWithSameToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.store(credentials, identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      #expect(retrievedAfter != nil)
      #expect(retrievedAfter == credentials)
    }
  }
}
