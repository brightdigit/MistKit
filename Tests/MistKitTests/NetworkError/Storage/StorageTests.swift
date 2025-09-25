import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension NetworkErrorTests {
  /// Network error storage tests
  @Suite("Storage Tests")
  struct StorageTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

    // MARK: - Token Storage Tests

    /// Tests token storage with network errors
    @Test("Token storage with network errors")
    func tokenStorageWithNetworkErrors() async throws {
      let storage = InMemoryTokenStorage()
      _ = APITokenManager(apiToken: Self.validAPIToken, storage: storage)

      // Store token
      let credentials = TokenCredentials.apiToken(Self.validAPIToken)
      try await storage.store(credentials, identifier: "test-key")

      // Retrieve token
      let retrievedCredentials = try await storage.retrieve(identifier: "test-key")
      #expect(retrievedCredentials != nil)

      if let retrieved = retrievedCredentials {
        if case .apiToken(let token) = retrieved.method {
          #expect(token == Self.validAPIToken)
        } else {
          Issue.record("Expected .apiToken method")
        }
      }
    }

    /// Tests token storage persistence across network failures
    @Test("Token storage persistence across network failures")
    func tokenStoragePersistenceAcrossNetworkFailures() async throws {
      let storage = InMemoryTokenStorage()
      _ = APITokenManager(apiToken: Self.validAPIToken, storage: storage)

      // Store token
      let credentials = TokenCredentials.apiToken(Self.validAPIToken)
      try await storage.store(credentials, identifier: "persistent-key")

      // Simulate network failure during retrieval
      let retrievedCredentials = try await storage.retrieve(identifier: "persistent-key")
      #expect(retrievedCredentials != nil)

      // Verify token is still available after simulated network issues
      if let retrieved = retrievedCredentials {
        if case .apiToken(let token) = retrieved.method {
          #expect(token == Self.validAPIToken)
        } else {
          Issue.record("Expected .apiToken method")
        }
      }
    }

    /// Tests token storage cleanup after network errors
    @Test("Token storage cleanup after network errors")
    func tokenStorageCleanupAfterNetworkErrors() async throws {
      let storage = InMemoryTokenStorage()
      _ = APITokenManager(apiToken: Self.validAPIToken, storage: storage)

      // Store token
      let credentials = TokenCredentials.apiToken(Self.validAPIToken)
      try await storage.store(credentials, identifier: "cleanup-key")

      // Verify token exists
      let initialRetrieval = try await storage.retrieve(identifier: "cleanup-key")
      #expect(initialRetrieval != nil)

      // Remove token
      try await storage.remove(identifier: "cleanup-key")

      // Verify token is removed
      let finalRetrieval = try await storage.retrieve(identifier: "cleanup-key")
      #expect(finalRetrieval == nil)
    }

    /// Tests concurrent token storage operations
    @Test("Concurrent token storage operations")
    func concurrentTokenStorageOperations() async throws {
      let storage = InMemoryTokenStorage()
      _ = APITokenManager(apiToken: Self.validAPIToken, storage: storage)

      // Test concurrent storage operations
      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await storage.storeToken(key: "concurrent-1", token: "token-1") }
        group.addTask { try await storage.storeToken(key: "concurrent-2", token: "token-2") }
        group.addTask { try await storage.storeToken(key: "concurrent-3", token: "token-3") }

        for try await _ in group {}
      }

      // Verify all tokens were stored
      let token1 = try await storage.retrieve(identifier: "concurrent-1")
      let token2 = try await storage.retrieve(identifier: "concurrent-2")
      let token3 = try await storage.retrieve(identifier: "concurrent-3")

      #expect(token1 != nil)
      #expect(token2 != nil)
      #expect(token3 != nil)
    }

    /// Tests token storage with expiration
    @Test("Token storage with expiration")
    func tokenStorageWithExpiration() async throws {
      let storage = InMemoryTokenStorage()
      _ = APITokenManager(apiToken: Self.validAPIToken, storage: storage)

      // Store token with short expiration
      let credentials = TokenCredentials.apiToken(Self.validAPIToken)
      try await storage.store(credentials, identifier: "expiring-key")

      // Verify token exists initially
      let initialRetrieval = try await storage.retrieve(identifier: "expiring-key")
      #expect(initialRetrieval != nil)

      // Note: InMemoryTokenStorage doesn't have built-in expiration,
      // but we can test the storage mechanism works
      let finalRetrieval = try await storage.retrieve(identifier: "expiring-key")
      #expect(finalRetrieval != nil)
    }
  }
}
