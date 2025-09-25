import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Concurrent removal tests for InMemoryTokenStorage
  @Suite("Concurrent Removal Tests")
  struct ConcurrentRemovalTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

    // MARK: - Concurrent Removal Tests

    /// Tests concurrent token removal
    @Test("Concurrent token removal")
    func concurrentTokenRemoval() async throws {
      let storage = InMemoryTokenStorage()

      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.apiToken("token2")
      let credentials3 = TokenCredentials.apiToken("token3")

      // Store multiple tokens
      try await storage.store(credentials1, identifier: "concurrent1")
      try await storage.store(credentials2, identifier: "concurrent2")
      try await storage.store(credentials3, identifier: "concurrent3")

      // Test concurrent removal
      async let task1 = storage.removeToken(identifier: "concurrent1")
      async let task2 = storage.removeToken(identifier: "concurrent2")
      async let task3 = storage.removeToken(identifier: "concurrent3")

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      // Verify all tokens are removed
      let identifiers = try await storage.listIdentifiers()
      #expect(!identifiers.contains("concurrent1"))
      #expect(!identifiers.contains("concurrent2"))
      #expect(!identifiers.contains("concurrent3"))
    }

    /// Tests concurrent removal and retrieval
    @Test("Concurrent removal and retrieval")
    func concurrentRemovalAndRetrieval() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: "concurrent-test")

      // Test concurrent removal and retrieval
      async let task1 = storage.removeToken(identifier: "concurrent-test")
      async let task2 = storage.getToken(identifier: "concurrent-test")
      async let task3 = storage.removeToken(identifier: "concurrent-test")

      let results = await (task1, task2, task3)
      // At least removal should succeed
      #expect(results.0 == true || results.2 == true)

      // Token should be removed
      let retrieved = try await storage.retrieve(identifier: "concurrent-test")
      #expect(retrieved == nil)
    }

    // MARK: - Storage State Tests

    /// Tests storage state after removal
    @Test("Storage state after removal")
    func storageStateAfterRemoval() async throws {
      let storage = InMemoryTokenStorage()

      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.apiToken("token2")

      // Store tokens
      try await storage.store(credentials1, identifier: "state1")
      try await storage.store(credentials2, identifier: "state2")

      // Verify storage is not empty
      let isEmptyBefore = await storage.isEmpty
      #expect(isEmptyBefore == false)

      let countBefore = await storage.count
      #expect(countBefore == 2)

      // Remove one token
      try await storage.remove(identifier: "state1")

      // Verify storage state
      let isEmptyAfter = await storage.isEmpty
      #expect(isEmptyAfter == false)

      let countAfter = await storage.count
      #expect(countAfter == 1)

      // Remove remaining token
      try await storage.remove(identifier: "state2")

      // Verify storage is empty
      let isEmptyFinal = await storage.isEmpty
      #expect(isEmptyFinal == true)

      let countFinal = await storage.count
      #expect(countFinal == 0)
    }
  }
}
