import Foundation
import Testing

@testable import MistKit

@Suite("Web Auth Token Manager")
public enum WebAuthTokenManagerTests {}

extension WebAuthTokenManagerTests {
  /// Basic functionality tests for WebAuthTokenManager
  @Suite("Basic Tests")
  public struct BasicTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"
    private static let invalidAPIToken = "invalid_token_format"
    private static let shortWebAuthToken = "short"

    // MARK: - Initialization Tests

    /// Tests WebAuthTokenManager initialization with valid tokens
    @Test("WebAuthTokenManager initialization with valid tokens")
    public func initializationWithValidTokens() {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      #expect(manager.apiToken == Self.validAPIToken)
      #expect(manager.webAuthToken == Self.validWebAuthToken)
    }

    /// Tests WebAuthTokenManager initialization with storage
    @Test("WebAuthTokenManager initialization with storage")
    public func initializationWithStorage() {
      let storage = InMemoryTokenStorage()
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken,
        storage: storage
      )

      #expect(manager.apiToken == Self.validAPIToken)
      #expect(manager.webAuthToken == Self.validWebAuthToken)
    }

    // MARK: - TokenManager Protocol Tests

    /// Tests hasCredentials property with valid tokens
    @Test("hasCredentials property with valid tokens")
    public func hasCredentialsWithValidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests validateCredentials with valid tokens
    @Test("validateCredentials with valid tokens")
    public func validateCredentialsWithValidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests getCurrentCredentials with valid tokens
    @Test("getCurrentCredentials with valid tokens")
    public func getCurrentCredentialsWithValidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let credentials = try await manager.getCurrentCredentials()
      #expect(credentials != nil)

      if let credentials = credentials {
        if case .webAuthToken(let api, let web) = credentials.method {
          #expect(api == Self.validAPIToken)
          #expect(web == Self.validWebAuthToken)
        } else {
          Issue.record("Expected .webAuthToken method")
        }
      }
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that WebAuthTokenManager can be used across async boundaries
    @Test("WebAuthTokenManager sendable compliance")
    public func sendableCompliance() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Test concurrent access patterns
      async let task1 = manager.validateManager()
      async let task2 = manager.getCredentialsFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
