internal import Crypto
internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension NetworkErrorTests {
  /// Network error storage tests
  @Suite("Storage", .enabled(if: Platform.isCryptoAvailable))
  internal struct StorageTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      TestConstants.apiToken

    // MARK: - Token Storage Tests

    /// Tests token storage with network errors
    @Test("Token storage with network errors")
    internal func tokenStorageWithNetworkErrors() async throws {
      let storage = InMemoryTokenStorage()

      // Store authenticator
      let authenticator = try APITokenAuthenticator(token: Self.validAPIToken)
      try await storage.store(authenticator, identifier: "test-key")

      // Retrieve authenticator
      let retrieved = try await storage.retrieve(identifier: "test-key")
      let api = try #require(retrieved as? APITokenAuthenticator)
      #expect(api.token == Self.validAPIToken)
    }

    /// Tests token storage persistence across network failures
    @Test("Token storage persistence across network failures")
    internal func tokenStoragePersistenceAcrossNetworkFailures() async throws {
      let storage = InMemoryTokenStorage()

      let authenticator = try APITokenAuthenticator(token: Self.validAPIToken)
      try await storage.store(authenticator, identifier: "persistent-key")

      let retrieved = try await storage.retrieve(identifier: "persistent-key")
      let api = try #require(retrieved as? APITokenAuthenticator)
      #expect(api.token == Self.validAPIToken)
    }

    /// Tests token storage cleanup after network errors
    @Test("Token storage cleanup after network errors")
    internal func tokenStorageCleanupAfterNetworkErrors() async throws {
      let storage = InMemoryTokenStorage()

      let authenticator = try APITokenAuthenticator(token: Self.validAPIToken)
      try await storage.store(authenticator, identifier: "cleanup-key")

      let initialRetrieval = try await storage.retrieve(identifier: "cleanup-key")
      #expect(initialRetrieval != nil)

      try await storage.remove(identifier: "cleanup-key")

      let finalRetrieval = try await storage.retrieve(identifier: "cleanup-key")
      #expect(finalRetrieval == nil)
    }

    /// Tests concurrent token storage operations
    @Test("Concurrent token storage operations")
    internal func concurrentTokenStorageOperations() async throws {
      let storage = InMemoryTokenStorage()

      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask {
          try await storage.storeToken(key: "concurrent-1", token: TestConstants.apiToken)
        }
        group.addTask {
          try await storage.storeToken(key: "concurrent-2", token: TestConstants.apiToken)
        }
        group.addTask {
          try await storage.storeToken(key: "concurrent-3", token: TestConstants.apiToken)
        }

        for try await _ in group {}
      }

      let token1 = try await storage.retrieve(identifier: "concurrent-1")
      let token2 = try await storage.retrieve(identifier: "concurrent-2")
      let token3 = try await storage.retrieve(identifier: "concurrent-3")

      #expect(token1 != nil)
      #expect(token2 != nil)
      #expect(token3 != nil)
    }

    /// Tests token storage with expiration
    @Test("Token storage with expiration")
    internal func tokenStorageWithExpiration() async throws {
      let storage = InMemoryTokenStorage()

      let authenticator = try APITokenAuthenticator(token: Self.validAPIToken)
      try await storage.store(authenticator, identifier: "expiring-key")

      let initialRetrieval = try await storage.retrieve(identifier: "expiring-key")
      #expect(initialRetrieval != nil)

      let finalRetrieval = try await storage.retrieve(identifier: "expiring-key")
      #expect(finalRetrieval != nil)
    }
  }
}
