import Foundation
import Testing

@testable import MistKit

@Suite("In-Memory Token Storage Retrieval")
/// Test suite for InMemoryTokenStorage token retrieval and removal functionality
internal struct InMemoryTokenStorageRetrievalTests {
  // MARK: - Test Data Setup

  private static let testAPIToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

  // MARK: - Token Retrieval Tests

  /// Tests retrieving stored token
  @Test("Retrieve stored token")
  internal func retrieveStoredToken() async throws {
    let storage = InMemoryTokenStorage()
    let credentials = TokenCredentials.apiToken(Self.testAPIToken)

    try await storage.store(credentials, identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved != nil)
    #expect(retrieved == credentials)
  }

  /// Tests retrieving non-existent token
  @Test("Retrieve non-existent token")
  internal func retrieveNonExistentToken() async throws {
    let storage = InMemoryTokenStorage()

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved == nil)
  }

  /// Tests retrieving token after clearing storage
  @Test("Retrieve token after clearing storage")
  internal func retrieveTokenAfterClearingStorage() async throws {
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
  internal func removeStoredToken() async throws {
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
  internal func removeNonExistentToken() async throws {
    let storage = InMemoryTokenStorage()

    // Should not throw or crash
    try await storage.remove(identifier: nil)

    let retrieved = try await storage.retrieve(identifier: nil)
    #expect(retrieved == nil)
  }
}
