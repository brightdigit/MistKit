import Foundation
import Testing

@testable import MistKit

internal enum InMemoryTokenStorageTests {}

extension InMemoryTokenStorageTests {
  /// Concurrent access tests for InMemoryTokenStorage
  @Suite("Concurrent Tests")
  internal struct ConcurrentTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

    // MARK: - Concurrent Access Tests

    /// Tests concurrent storage operations
    @Test("Concurrent storage operations")
    internal func concurrentStorageOperations() async throws {
      let storage = InMemoryTokenStorage()
      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.apiToken("token2")
      let credentials3 = TokenCredentials.apiToken("token3")

      // Test concurrent storage operations
      async let task1 = storage.storeCredentials(credentials1)
      async let task2 = storage.storeCredentials(credentials2)
      async let task3 = storage.storeCredentials(credentials3)

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      // Verify that one of the credentials was stored
      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved != nil)
    }

    /// Tests concurrent retrieval operations
    @Test("Concurrent retrieval operations")
    internal func concurrentRetrievalOperations() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)

      // Test concurrent retrieval operations
      async let task1 = storage.getCredentials()
      async let task2 = storage.getCredentials()
      async let task3 = storage.getCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 != nil)
      #expect(results.1 != nil)
      #expect(results.2 != nil)

      // All should return the same credentials
      #expect(results.0 == results.1)
      #expect(results.1 == results.2)
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that InMemoryTokenStorage can be used across async boundaries
    @Test("InMemoryTokenStorage sendable compliance")
    internal func sendableCompliance() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      // Test concurrent access patterns
      async let task1 = storage.storeAndRetrieve(credentials)
      async let task2 = storage.storeAndRetrieve(credentials)
      async let task3 = storage.storeAndRetrieve(credentials)

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)
    }
  }
}
