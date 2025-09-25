import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Token removal tests for InMemoryTokenStorage
  @Suite("Removal Tests")
  struct RemovalTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let testWebAuthToken = "user123_web_auth_token_abcdef"

    // MARK: - Basic Removal Tests

    /// Tests removing stored token by identifier
    @Test("Remove stored token by identifier")
    func removeStoredTokenByIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: "test-token")

      let retrievedBefore = try await storage.retrieve(identifier: "test-token")
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: "test-token")

      let retrievedAfter = try await storage.retrieve(identifier: "test-token")
      #expect(retrievedAfter == nil)
    }

    /// Tests removing non-existent token
    @Test("Remove non-existent token")
    func removeNonExistentToken() async throws {
      let storage = InMemoryTokenStorage()

      // Should not throw or crash
      try await storage.remove(identifier: "non-existent")

      let retrieved = try await storage.retrieve(identifier: "non-existent")
      #expect(retrieved == nil)
    }

    /// Tests removing token with nil identifier
    @Test("Remove token with nil identifier")
    func removeTokenWithNilIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      #expect(retrievedAfter == nil)
    }

    // MARK: - Multiple Token Removal Tests

    /// Tests removing specific token from multiple stored tokens
    @Test("Remove specific token from multiple stored tokens")
    func removeSpecificTokenFromMultipleStoredTokens() async throws {
      let storage = InMemoryTokenStorage()

      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.webAuthToken(
        apiToken: Self.testAPIToken,
        webToken: Self.testWebAuthToken
      )
      let credentials3 = TokenCredentials.apiToken("token3")

      // Store multiple tokens
      try await storage.store(credentials1, identifier: "api1")
      try await storage.store(credentials2, identifier: "web")
      try await storage.store(credentials3, identifier: "api3")

      // Verify all tokens are stored
      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      // Remove specific token
      try await storage.remove(identifier: "web")

      // Verify only specific token is removed
      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.count == 2)
      #expect(identifiersAfter.contains("api1"))
      #expect(identifiersAfter.contains("api3"))
      #expect(!identifiersAfter.contains("web"))

      // Verify removed token is gone
      let retrievedWeb = try await storage.retrieve(identifier: "web")
      #expect(retrievedWeb == nil)

      // Verify other tokens remain
      let retrievedApi1 = try await storage.retrieve(identifier: "api1")
      let retrievedApi3 = try await storage.retrieve(identifier: "api3")
      #expect(retrievedApi1 != nil)
      #expect(retrievedApi3 != nil)
    }

    /// Tests removing all tokens by clearing storage
    @Test("Remove all tokens by clearing storage")
    func removeAllTokensByClearingStorage() async throws {
      let storage = InMemoryTokenStorage()

      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.webAuthToken(
        apiToken: Self.testAPIToken,
        webToken: Self.testWebAuthToken
      )
      let credentials3 = TokenCredentials.apiToken("token3")

      // Store multiple tokens
      try await storage.store(credentials1, identifier: "api1")
      try await storage.store(credentials2, identifier: "web")
      try await storage.store(credentials3, identifier: "api3")

      // Verify all tokens are stored
      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      // Clear all tokens
      await storage.clear()

      // Verify all tokens are removed
      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.isEmpty)

      // Verify all tokens are gone
      let retrievedApi1 = try await storage.retrieve(identifier: "api1")
      let retrievedWeb = try await storage.retrieve(identifier: "web")
      let retrievedApi3 = try await storage.retrieve(identifier: "api3")
      #expect(retrievedApi1 == nil)
      #expect(retrievedWeb == nil)
      #expect(retrievedApi3 == nil)
    }

    // MARK: - Edge Case Removal Tests

    /// Tests removing token with empty string identifier
    @Test("Remove token with empty string identifier")
    func removeTokenWithEmptyStringIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: "")

      let retrievedBefore = try await storage.retrieve(identifier: "")
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: "")

      let retrievedAfter = try await storage.retrieve(identifier: "")
      #expect(retrievedAfter == nil)
    }

    /// Tests removing token with special characters in identifier
    @Test("Remove token with special characters in identifier")
    func removeTokenWithSpecialCharactersInIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let specialIdentifier = "test@#$%^&*()_+-={}[]|\\:;\"'<>?,./"

      try await storage.store(credentials, identifier: specialIdentifier)

      let retrievedBefore = try await storage.retrieve(identifier: specialIdentifier)
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: specialIdentifier)

      let retrievedAfter = try await storage.retrieve(identifier: specialIdentifier)
      #expect(retrievedAfter == nil)
    }

    /// Tests removing expired token
    @Test("Remove expired token")
    func removeExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-3_600)  // 1 hour ago (expired)

      try await storage.store(credentials, identifier: "expired", expirationTime: expirationTime)

      // Token should already be expired and not retrievable
      let retrievedBefore = try await storage.retrieve(identifier: "expired")
      #expect(retrievedBefore == nil)

      // Remove should still work even though token is expired
      try await storage.remove(identifier: "expired")

      let retrievedAfter = try await storage.retrieve(identifier: "expired")
      #expect(retrievedAfter == nil)
    }
  }
}
