import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Expiration handling tests for InMemoryTokenStorage
  @Suite("Expiration")
  internal struct ExpirationTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken

    // MARK: - Token Expiration Tests

    /// Tests storing token with expiration time
    @Test("Store token with expiration time")
    internal func storeTokenWithExpirationTime() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)

      try await storage.store(
        authenticator,
        identifier: "test",
        expirationTime: expirationTime
      )

      let retrieved = try await storage.retrieve(identifier: "test")
      let api = try #require(retrieved as? APITokenAuthenticator)
      #expect(api.token == Self.testAPIToken)
    }

    /// Tests retrieving expired token
    @Test("Retrieve expired token")
    internal func retrieveExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-3_600)

      try await storage.store(
        authenticator,
        identifier: "expired",
        expirationTime: expirationTime
      )

      let retrieved = try await storage.retrieve(identifier: "expired")
      #expect(retrieved == nil)
    }

    /// Tests retrieving non-expired token
    @Test("Retrieve non-expired token")
    internal func retrieveNonExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)

      try await storage.store(
        authenticator,
        identifier: "valid",
        expirationTime: expirationTime
      )

      let retrieved = try await storage.retrieve(identifier: "valid")
      #expect(retrieved != nil)
    }

    /// Tests storing token without expiration time
    @Test("Store token without expiration time")
    internal func storeTokenWithoutExpirationTime() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: "no-expiry", expirationTime: nil)

      let retrieved = try await storage.retrieve(identifier: "no-expiry")
      #expect(retrieved != nil)
    }

    /// Tests token expiration cleanup
    @Test("Token expiration cleanup")
    internal func tokenExpirationCleanup() async throws {
      let storage = InMemoryTokenStorage()
      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(
        auth1,
        identifier: "expired1",
        expirationTime: Date().addingTimeInterval(-3_600)
      )
      try await storage.store(
        auth2,
        identifier: "expired2",
        expirationTime: Date().addingTimeInterval(-1_800)
      )
      try await storage.store(
        auth3,
        identifier: "valid",
        expirationTime: Date().addingTimeInterval(3_600)
      )

      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      await storage.cleanupExpiredTokens()

      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.count == 1)
      #expect(identifiersAfter.contains("valid"))

      let retrievedExpired1 = try await storage.retrieve(identifier: "expired1")
      let retrievedExpired2 = try await storage.retrieve(identifier: "expired2")
      let retrievedValid = try await storage.retrieve(identifier: "valid")

      #expect(retrievedExpired1 == nil)
      #expect(retrievedExpired2 == nil)
      #expect(retrievedValid != nil)
    }

    /// Tests automatic expiration during retrieval
    @Test("Automatic expiration during retrieval")
    internal func automaticExpirationDuringRetrieval() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-1)

      try await storage.store(
        authenticator,
        identifier: "auto-expired",
        expirationTime: expirationTime
      )

      let retrieved = try await storage.retrieve(identifier: "auto-expired")
      #expect(retrieved == nil)

      let identifiers = try await storage.listIdentifiers()
      #expect(!identifiers.contains("auto-expired"))
    }

    /// Tests storing multiple tokens with different expiration times
    @Test("Store multiple tokens with different expiration times")
    internal func storeMultipleTokensWithDifferentExpirationTimes() async throws {
      let storage = InMemoryTokenStorage()
      let now = Date()

      let auth1 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth2 = try APITokenAuthenticator(token: Self.testAPIToken)
      let auth3 = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(
        auth1,
        identifier: "short",
        expirationTime: now.addingTimeInterval(60)
      )
      try await storage.store(
        auth2,
        identifier: "medium",
        expirationTime: now.addingTimeInterval(3_600)
      )
      try await storage.store(
        auth3,
        identifier: "long",
        expirationTime: now.addingTimeInterval(86_400)
      )

      let retrieved1 = try await storage.retrieve(identifier: "short")
      let retrieved2 = try await storage.retrieve(identifier: "medium")
      let retrieved3 = try await storage.retrieve(identifier: "long")

      #expect(retrieved1 != nil)
      #expect(retrieved2 != nil)
      #expect(retrieved3 != nil)
    }

    /// Tests expiration time edge cases
    @Test("Expiration time edge cases")
    internal func expirationTimeEdgeCases() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      let exactExpiration = Date()
      try await storage.store(
        authenticator,
        identifier: "exact",
        expirationTime: exactExpiration
      )

      let retrieved = try await storage.retrieve(identifier: "exact")
      #expect(retrieved == nil)
    }

    /// Tests concurrent access with expiration
    @Test("Concurrent access with expiration")
    internal func concurrentAccessWithExpiration() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)

      try await storage.store(
        authenticator,
        identifier: "concurrent",
        expirationTime: expirationTime
      )

      async let task1 = storage.getAuthenticator(identifier: "concurrent")
      async let task2 = storage.getAuthenticator(identifier: "concurrent")
      async let task3 = storage.getAuthenticator(identifier: "concurrent")

      let results = await (task1, task2, task3)
      #expect(results.0 != nil)
      #expect(results.1 != nil)
      #expect(results.2 != nil)
    }
  }
}
