import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Concurrent removal tests for InMemoryTokenStorage
  @Suite("Concurrent Removal")
  internal struct ConcurrentRemovalTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken

    // MARK: - Concurrent Removal Tests

    /// Tests concurrent token removal
    @Test("Concurrent token removal")
    internal func concurrentTokenRemoval() async throws {
      let storage = InMemoryTokenStorage()

      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(auth1, identifier: "concurrent1")
      try await storage.store(auth2, identifier: "concurrent2")
      try await storage.store(auth3, identifier: "concurrent3")

      async let task1 = storage.removeToken(identifier: "concurrent1")
      async let task2 = storage.removeToken(identifier: "concurrent2")
      async let task3 = storage.removeToken(identifier: "concurrent3")

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      let identifiers = try await storage.listIdentifiers()
      #expect(!identifiers.contains("concurrent1"))
      #expect(!identifiers.contains("concurrent2"))
      #expect(!identifiers.contains("concurrent3"))
    }

    /// Tests concurrent removal and retrieval
    @Test("Concurrent removal and retrieval")
    internal func concurrentRemovalAndRetrieval() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: "concurrent-test")

      async let task1 = storage.removeToken(identifier: "concurrent-test")
      async let task2 = storage.getToken(identifier: "concurrent-test")
      async let task3 = storage.removeToken(identifier: "concurrent-test")

      let results = await (task1, task2, task3)
      _ = results.1
      #expect(results.0 == true || results.2 == true)

      let retrieved = try await storage.retrieve(identifier: "concurrent-test")
      #expect(retrieved == nil)
    }

    // MARK: - Storage State Tests

    /// Tests storage state after removal
    @Test("Storage state after removal")
    internal func storageStateAfterRemoval() async throws {
      let storage = InMemoryTokenStorage()

      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(auth1, identifier: "state1")
      try await storage.store(auth2, identifier: "state2")

      let isEmptyBefore = await storage.isEmpty
      #expect(isEmptyBefore == false)

      let countBefore = await storage.count
      #expect(countBefore == 2)

      try await storage.remove(identifier: "state1")

      let isEmptyAfter = await storage.isEmpty
      #expect(isEmptyAfter == false)

      let countAfter = await storage.count
      #expect(countAfter == 1)

      try await storage.remove(identifier: "state2")

      let isEmptyFinal = await storage.isEmpty
      #expect(isEmptyFinal == true)

      let countFinal = await storage.count
      #expect(countFinal == 0)
    }
  }
}
