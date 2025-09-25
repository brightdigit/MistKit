import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Credential validation tests for WebAuthTokenManager
  @Suite("Validation Credential Tests")
  internal struct ValidationCredentialTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"
    private static let invalidAPIToken = "invalid_token_format"
    private static let shortWebAuthToken = "short"

    // MARK: - Credential Validation Tests

    /// Tests hasCredentials with valid tokens
    @Test("hasCredentials with valid tokens")
    internal func hasCredentialsWithValidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests hasCredentials with invalid tokens
    @Test("hasCredentials with invalid tokens")
    internal func hasCredentialsWithInvalidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.invalidAPIToken,
        webAuthToken: Self.shortWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == false)
    }

    /// Tests getCurrentCredentials with valid tokens
    @Test("getCurrentCredentials with valid tokens")
    internal func getCurrentCredentialsWithValidTokens() async throws {
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

    /// Tests getCurrentCredentials with invalid tokens
    @Test("getCurrentCredentials with invalid tokens")
    internal func getCurrentCredentialsWithInvalidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.invalidAPIToken,
        webAuthToken: Self.shortWebAuthToken
      )

      do {
        _ = try await manager.getCurrentCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
