internal import Foundation
internal import Testing

@testable import MistKit

internal enum InMemoryTokenStorageTests {}

extension InMemoryTokenStorageTests {
  /// Concurrent access tests for InMemoryTokenStorage
  @Suite("Concurrent")
  internal struct ConcurrentTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken

    // MARK: - Concurrent Access Tests

    /// Tests concurrent storage operations
    @Test("Concurrent storage operations")
    internal func concurrentStorageOperations() async throws {
      let storage = InMemoryTokenStorage()
      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      async let task1 = storage.storeAuthenticator(auth1)
      async let task2 = storage.storeAuthenticator(auth2)
      async let task3 = storage.storeAuthenticator(auth3)

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      let retrieved = try await storage.retrieve(identifier: nil)
      #expect(retrieved != nil)
    }

    /// Tests concurrent retrieval operations
    @Test("Concurrent retrieval operations")
    internal func concurrentRetrievalOperations() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: nil)

      async let task1 = storage.getAuthenticator()
      async let task2 = storage.getAuthenticator()
      async let task3 = storage.getAuthenticator()

      let results = await (task1, task2, task3)
      let api1 = try #require(results.0 as? APITokenAuthenticator)
      let api2 = try #require(results.1 as? APITokenAuthenticator)
      let api3 = try #require(results.2 as? APITokenAuthenticator)
      #expect(api1.token == Self.testAPIToken)
      #expect(api2.token == api1.token)
      #expect(api3.token == api1.token)
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that InMemoryTokenStorage can be used across async boundaries
    @Test("InMemoryTokenStorage sendable compliance")
    internal func sendableCompliance() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      async let task1 = storage.storeAndRetrieve(authenticator)
      async let task2 = storage.storeAndRetrieve(authenticator)
      async let task3 = storage.storeAndRetrieve(authenticator)

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)
    }
  }
}
