import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Test suite for InMemoryTokenStorage token replacement functionality
  @Suite("In-Memory Token Storage Replacement")
  internal struct ReplacementTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken
    private static let testWebAuthToken = TestConstants.webAuthToken

    // MARK: - Token Replacement Tests

    /// Tests replacing stored token with new token
    @Test("Replace stored token with new token")
    internal func replaceStoredTokenWithNewToken() async throws {
      let storage = InMemoryTokenStorage()
      let original = try APITokenAuthenticator(token: Self.testAPIToken)
      let replacement = try WebAuthTokenAuthenticator(
        apiToken: Self.testAPIToken,
        webAuthToken: Self.testWebAuthToken
      )

      try await storage.store(original, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore is APITokenAuthenticator)

      try await storage.store(replacement, identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      let web = try #require(retrievedAfter as? WebAuthTokenAuthenticator)
      #expect(web.apiToken == replacement.apiToken)
      #expect(web.webAuthToken == replacement.webAuthToken)
    }

    /// Tests replacing stored token with same token
    @Test("Replace stored token with same token")
    internal func replaceStoredTokenWithSameToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: nil)

      let retrievedBefore = try await storage.retrieve(identifier: nil)
      #expect(retrievedBefore != nil)

      try await storage.store(authenticator, identifier: nil)

      let retrievedAfter = try await storage.retrieve(identifier: nil)
      let api = try #require(retrievedAfter as? APITokenAuthenticator)
      #expect(api.token == authenticator.token)
    }
  }
}
