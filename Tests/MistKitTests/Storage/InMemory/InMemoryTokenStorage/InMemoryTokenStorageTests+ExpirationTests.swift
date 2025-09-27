import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Expiration handling tests for InMemoryTokenStorage
  @Suite("Expiration Tests")
  internal struct ExpirationTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"

    // MARK: - Token Expiration Tests

    /// Tests storing token with expiration time
    @Test("Store token with expiration time")
    internal func storeTokenWithExpirationTime() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)  // 1 hour from now

      try await storage.store(credentials, identifier: "test", expirationTime: expirationTime)

      let retrieved = try await storage.retrieve(identifier: "test")
      #expect(retrieved != nil)

      if let retrieved = retrieved {
        if case .apiToken(let token) = retrieved.method {
          #expect(token == Self.testAPIToken)
        } else {
          Issue.record("Expected .apiToken method")
        }
      }
    }

    /// Tests retrieving expired token
    @Test("Retrieve expired token")
    internal func retrieveExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-3_600)  // 1 hour ago (expired)

      try await storage.store(credentials, identifier: "expired", expirationTime: expirationTime)

      let retrieved = try await storage.retrieve(identifier: "expired")
      #expect(retrieved == nil)  // Should be nil because token is expired
    }

    /// Tests retrieving non-expired token
    @Test("Retrieve non-expired token")
    internal func retrieveNonExpiredToken() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)  // 1 hour from now

      try await storage.store(credentials, identifier: "valid", expirationTime: expirationTime)

      let retrieved = try await storage.retrieve(identifier: "valid")
      #expect(retrieved != nil)  // Should not be nil because token is not expired
    }

    /// Tests storing token without expiration time
    @Test("Store token without expiration time")
    internal func storeTokenWithoutExpirationTime() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      try await storage.store(credentials, identifier: "no-expiry", expirationTime: nil)

      let retrieved = try await storage.retrieve(identifier: "no-expiry")
      #expect(retrieved != nil)  // Should not be nil because no expiration time
    }

    /// Tests token expiration cleanup
    @Test("Token expiration cleanup")
    internal func tokenExpirationCleanup() async throws {
      let storage = InMemoryTokenStorage()
      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.apiToken("token2")
      let credentials3 = TokenCredentials.apiToken("token3")

      // Store tokens with different expiration times
      try await storage.store(
        credentials1,
        identifier: "expired1",
        expirationTime: Date().addingTimeInterval(-3_600)
      )
      try await storage.store(
        credentials2,
        identifier: "expired2",
        expirationTime: Date().addingTimeInterval(-1_800)
      )
      try await storage.store(
        credentials3,
        identifier: "valid",
        expirationTime: Date().addingTimeInterval(3_600)
      )

      // Verify all tokens are initially stored
      let identifiersBefore = try await storage.listIdentifiers()
      #expect(identifiersBefore.count == 3)

      // Clean up expired tokens
      await storage.cleanupExpiredTokens()

      // Verify only non-expired token remains
      let identifiersAfter = try await storage.listIdentifiers()
      #expect(identifiersAfter.count == 1)
      #expect(identifiersAfter.contains("valid"))

      // Verify expired tokens are gone
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
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(-1)  // Just expired

      try await storage.store(
        credentials,
        identifier: "auto-expired",
        expirationTime: expirationTime
      )

      // First retrieval should return nil due to expiration
      let retrieved = try await storage.retrieve(identifier: "auto-expired")
      #expect(retrieved == nil)

      // Token should be automatically removed from storage
      let identifiers = try await storage.listIdentifiers()
      #expect(!identifiers.contains("auto-expired"))
    }

    /// Tests storing multiple tokens with different expiration times
    @Test("Store multiple tokens with different expiration times")
    internal func storeMultipleTokensWithDifferentExpirationTimes() async throws {
      let storage = InMemoryTokenStorage()
      let now = Date()

      let credentials1 = TokenCredentials.apiToken("token1")
      let credentials2 = TokenCredentials.apiToken("token2")
      let credentials3 = TokenCredentials.apiToken("token3")

      // Store tokens with different expiration times
      try await storage.store(
        credentials1,
        identifier: "short",
        expirationTime: now.addingTimeInterval(60)
      )  // 1 minute
      try await storage.store(
        credentials2,
        identifier: "medium",
        expirationTime: now.addingTimeInterval(3_600)
      )  // 1 hour
      try await storage.store(
        credentials3,
        identifier: "long",
        expirationTime: now.addingTimeInterval(86_400)
      )  // 1 day

      // All should be retrievable initially
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
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)

      // Test with expiration time exactly at current time
      let exactExpiration = Date()
      try await storage.store(credentials, identifier: "exact", expirationTime: exactExpiration)

      let retrieved = try await storage.retrieve(identifier: "exact")
      #expect(retrieved == nil)  // Should be expired
    }

    /// Tests concurrent access with expiration
    @Test("Concurrent access with expiration")
    internal func concurrentAccessWithExpiration() async throws {
      let storage = InMemoryTokenStorage()
      let credentials = TokenCredentials.apiToken(Self.testAPIToken)
      let expirationTime = Date().addingTimeInterval(3_600)  // 1 hour from now

      try await storage.store(credentials, identifier: "concurrent", expirationTime: expirationTime)

      // Test concurrent retrieval of non-expired token
      async let task1 = storage.getCredentials(identifier: "concurrent")
      async let task2 = storage.getCredentials(identifier: "concurrent")
      async let task3 = storage.getCredentials(identifier: "concurrent")

      let results = await (task1, task2, task3)
      #expect(results.0 != nil)
      #expect(results.1 != nil)
      #expect(results.2 != nil)
    }
  }
}
