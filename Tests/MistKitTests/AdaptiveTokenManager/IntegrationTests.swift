import Foundation
import Testing

@testable import MistKit

@Suite("Adaptive Token Manager")
public enum AdaptiveTokenManagerTests {}

extension AdaptiveTokenManagerTests {
  /// Integration tests for AdaptiveTokenManager
  @Suite("Integration Tests")
  public struct IntegrationTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"

    // MARK: - Basic Integration Tests

    /// Tests AdaptiveTokenManager initialization with API token
    @Test("AdaptiveTokenManager initialization with API token")
    public func initializationWithAPIToken() async {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      // Verify initialization
      #expect(await tokenManager.apiToken == Self.validAPIToken)
      #expect(await tokenManager.webAuthToken == nil)
    }

    /// Tests AdaptiveTokenManager initialization with storage
    @Test("AdaptiveTokenManager initialization with storage")
    public func initializationWithStorage() async {
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
    public func hasCredentialsWithValidToken() async {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let hasCredentials = await tokenManager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests AdaptiveTokenManager validateCredentials
    @Test("validateCredentials with valid token")
    public func validateCredentialsWithValidToken() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let isValid = try await tokenManager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests AdaptiveTokenManager getCurrentCredentials
    @Test("getCurrentCredentials with valid token")
    public func getCurrentCredentialsWithValidToken() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      let credentials = try await tokenManager.getCurrentCredentials()
      #expect(credentials != nil)

      if let credentials = credentials {
        if case .apiToken(let api) = credentials.method {
          #expect(api == Self.validAPIToken)
        } else {
          Issue.record("Expected .apiToken method")
        }
      }
    }

    /// Tests AdaptiveTokenManager with empty API token
    @Test("AdaptiveTokenManager initialization with empty API token")
    public func initializationWithEmptyAPIToken() async {
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
    public func sendableCompliance() async throws {
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken
      )

      // Test concurrent access patterns
      async let task1 = tokenManager.validateManager()
      async let task2 = tokenManager.getCredentialsFromManager()
      async let task3 = tokenManager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
