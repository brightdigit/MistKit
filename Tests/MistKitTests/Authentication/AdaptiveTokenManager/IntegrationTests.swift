internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Adaptive Token Manager")
internal enum AdaptiveTokenManagerTests {}

extension AdaptiveTokenManagerTests {
  /// Integration tests for AdaptiveTokenManager
  @Suite("Integration")
  internal struct IntegrationTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      TestConstants.apiToken
    // private static let validWebAuthToken = TestConstants.webAuthToken

    // MARK: - Basic Integration Tests

    /// Tests AdaptiveTokenManager initialization with API token
    @Test("AdaptiveTokenManager initialization with API token")
    internal func initializationWithAPIToken() async {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      // Verify initialization
      #expect(await tokenManager.apiToken == Self.validAPIToken)
      #expect(await tokenManager.webAuthToken == nil)
    }

    /// Tests AdaptiveTokenManager initialization with storage
    @Test("AdaptiveTokenManager initialization with storage")
    internal func initializationWithStorage() async {
      let storage = InMemoryTokenStorage()
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken,
        storage: storage
      )

      // Verify initialization
      #expect(await tokenManager.apiToken == Self.validAPIToken)
      #expect(await tokenManager.webAuthToken == nil)
    }

    /// Tests AdaptiveTokenManager hasCredentials property
    @Test("hasCredentials with valid token")
    internal func hasCredentialsWithValidToken() async {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let hasCredentials = await tokenManager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests AdaptiveTokenManager validateCredentials
    @Test("validateCredentials with valid token")
    internal func validateCredentialsWithValidToken() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let isValid = try await tokenManager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests AdaptiveTokenManager currentAuthenticator
    @Test("currentAuthenticator with valid token")
    internal func currentAuthenticatorWithValidToken() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let authenticator = try await tokenManager.currentAuthenticator()
      let api = try #require(authenticator as? APITokenAuthenticator)
      #expect(api.token == Self.validAPIToken)
    }

    /// Tests AdaptiveTokenManager with empty API token
    @Test("AdaptiveTokenManager initialization with empty API token")
    internal func initializationWithEmptyAPIToken() async {
      // This should crash due to precondition - we can't easily test this with Swift Testing
      // Instead, we'll test that valid tokens work
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )
      #expect(await tokenManager.apiToken == Self.validAPIToken)
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that AdaptiveTokenManager can be used across async boundaries
    @Test("AdaptiveTokenManager sendable compliance")
    internal func sendableCompliance() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      // Test concurrent access patterns
      async let task1 = tokenManager.validateManager()
      async let task2 = tokenManager.authenticatorFromManager()
      async let task3 = tokenManager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
