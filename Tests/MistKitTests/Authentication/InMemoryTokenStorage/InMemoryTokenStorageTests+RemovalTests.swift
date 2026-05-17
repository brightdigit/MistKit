import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Token removal tests for InMemoryTokenStorage
  @Suite("Removal")
  internal struct RemovalTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken
    private static let testWebAuthToken = TestConstants.webAuthToken

    // MARK: - Basic Removal Tests

    /// Tests removing stored token by identifier
    @Test("Remove stored token by identifier")
    internal func removeStoredTokenByIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: "test-token")

      let retrievedBefore = try await storage.retrieve(identifier: "test-token")
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: "test-token")

      let retrievedAfter = try await storage.retrieve(identifier: "test-token")
      #expect(retrievedAfter == nil)
    }

    /// Tests removing non-existent token
    @Test("Remove non-existent token")
    internal func removeNonExistentToken() async throws {
      let storage = InMemoryTokenStorage()

      try await storage.remove(identifier: "non-existent")

      let retrieved = try await storage.retrieve(identifier: "non-existent")
      #expect(retrieved == nil)
    }

    /// Tests removing token with nil identifier
    @Test("Remove token with nil identifier")
    internal func removeTokenWithNilIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      #expect(retrievedAfter == nil)
    }

    // MARK: - Multiple Token Removal Tests

    /// Tests removing specific token from multiple stored tokens
    @Test("Remove specific token from multiple stored tokens")
    internal func removeSpecificTokenFromMultipleStoredTokens() async throws {
      let storage = InMemoryTokenStorage()

      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try WebAuthTokenAuthenticator(
        apiToken: Self.testAPIToken,
        webAuthToken: Self.testWebAuthToken
      )
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(auth1, identifier: "api1")
      try await storage.store(auth2, identifier: "web")
      try await storage.store(auth3, identifier: "api3")

      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      try await storage.remove(identifier: "web")

      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.count == 2)
      #expect(identifiersAfter.contains("api1"))
      #expect(identifiersAfter.contains("api3"))
      #expect(!identifiersAfter.contains("web"))

      let retrievedWeb = try await storage.retrieve(identifier: "web")
      #expect(retrievedWeb == nil)

      let retrievedApi1 = try await storage.retrieve(identifier: "api1")
      let retrievedApi3 = try await storage.retrieve(identifier: "api3")
      #expect(retrievedApi1 != nil)
      #expect(retrievedApi3 != nil)
    }

    /// Tests removing all tokens by clearing storage
    @Test("Remove all tokens by clearing storage")
    internal func removeAllTokensByClearingStorage() async throws {
      let storage = InMemoryTokenStorage()

      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try WebAuthTokenAuthenticator(
        apiToken: Self.testAPIToken,
        webAuthToken: Self.testWebAuthToken
      )
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(auth1, identifier: "api1")
      try await storage.store(auth2, identifier: "web")
      try await storage.store(auth3, identifier: "api3")

      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      await storage.clear()

      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.isEmpty)

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
    internal func removeTokenWithEmptyStringIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: "")

      let retrievedBefore = try await storage.retrieve(identifier: "")
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: "")

      let retrievedAfter = try await storage.retrieve(identifier: "")
      #expect(retrievedAfter == nil)
    }

    /// Tests removing token with special characters in identifier
    @Test("Remove token with special characters in identifier")
    internal func removeTokenWithSpecialCharactersInIdentifier() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let specialIdentifier = "test@#$%^&*()_+-={}[]|\\:;\"'<>?,./"

      try await storage.store(authenticator, identifier: specialIdentifier)

      let retrievedBefore = try await storage.retrieve(identifier: specialIdentifier)
      #expect(retrievedBefore != nil)

      try await storage.remove(identifier: specialIdentifier)

      let retrievedAfter = try await storage.retrieve(identifier: specialIdentifier)
      #expect(retrievedAfter == nil)
    }

    /// Tests removing expired token
    @Test("Remove expired token")
    internal func removeExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-3_600)

      try await storage.store(
        authenticator,
        identifier: "expired",
        expirationTime: expirationTime
      )

      let retrievedBefore = try await storage.retrieve(identifier: "expired")
      #expect(retrievedBefore == nil)

      try await storage.remove(identifier: "expired")

      let retrievedAfter = try await storage.retrieve(identifier: "expired")
      #expect(retrievedAfter == nil)
    }
  }
}
