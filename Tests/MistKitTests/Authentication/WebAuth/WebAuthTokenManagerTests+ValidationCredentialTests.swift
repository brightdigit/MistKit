import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Credential validation tests for WebAuthTokenManager
  @Suite("Validation Credential")
  internal struct Validation {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      TestConstants.apiToken
    private static let validWebAuthToken = TestConstants.webAuthToken
    private static let invalidAPIToken = "invalid_token_format"
    private static let shortWebAuthToken = "short"

    // MARK: - Credential Validation Tests

    /// Tests hasCredentials with valid tokens
    @Test("hasCredentials with valid tokens")
    internal func hasCredentialsValidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)
    }

    /// Tests hasCredentials with invalid tokens
    @Test("hasCredentials with invalid tokens")
    internal func hasCredentialsInvalidTokens() async {
      let manager = WebAuthTokenManager(
        apiToken: Self.invalidAPIToken,
        webAuthToken: Self.shortWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == false)
    }

    /// Tests currentAuthenticator with valid tokens
    @Test("currentAuthenticator with valid tokens")
    internal func currentAuthenticatorValidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let authenticator = try await manager.currentAuthenticator()
      let web = try #require(authenticator as? WebAuthTokenAuthenticator)
      #expect(web.apiToken == Self.validAPIToken)
      #expect(web.webAuthToken == Self.validWebAuthToken)
    }

    /// Tests currentAuthenticator with invalid tokens
    @Test("currentAuthenticator with invalid tokens")
    internal func currentAuthenticatorInvalidTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.invalidAPIToken,
        webAuthToken: Self.shortWebAuthToken
      )

      do {
        _ = try await manager.currentAuthenticator()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
