import Foundation
import Testing

@testable import MistKit

@Suite("Web Auth Token Manager")
internal enum WebAuthTokenManagerTests {}

extension WebAuthTokenManagerTests {
  /// Basic functionality tests for WebAuthTokenManager
  @Suite("Basic")
  internal struct Basic {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      TestConstants.apiToken
    private static let validWebAuthToken = TestConstants.webAuthToken
    //    private static let invalidAPIToken = "invalid_token_format"
    //    private static let shortWebAuthToken = "short"

    // MARK: - Initialization Tests

    /// Tests WebAuthTokenManager initialization with valid tokens
    @Test("WebAuthTokenManager initialization with valid tokens")
    internal func initializationWithValidTokens() {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      #expect(manager.apiToken == Self.validAPIToken)
      #expect(manager.webAuthToken == Self.validWebAuthToken)
    }

    /// Tests WebAuthTokenManager initialization with storage
    @Test("WebAuthTokenManager initialization with storage")
    internal func initializationWithStorage() {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      #expect(manager.apiToken == Self.validAPIToken)
      #expect(manager.webAuthToken == Self.validWebAuthToken)
    }

    // MARK: - TokenManager Protocol Tests

    /// Tests hasCredentials property with valid tokens
    @Test("hasCredentials property with valid tokens")
    internal func hasCredentialsWithValidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests validateCredentials with valid tokens
    @Test("validateCredentials with valid tokens")
    internal func validateCredentialsWithValidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests currentAuthenticator with valid tokens
    @Test("currentAuthenticator with valid tokens")
    internal func currentAuthenticatorWithValidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let authenticator = try await manager.currentAuthenticator()
      let web = try #require(authenticator as? WebAuthTokenAuthenticator)
      #expect(web.apiToken == Self.validAPIToken)
      #expect(web.webAuthToken == Self.validWebAuthToken)
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that WebAuthTokenManager can be used across async boundaries
    @Test("WebAuthTokenManager sendable compliance")
    internal func sendableCompliance() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Test concurrent access patterns
      async let task1 = manager.validateManager()
      async let task2 = manager.authenticatorFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
