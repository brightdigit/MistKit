import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Token format validation tests for WebAuthTokenManager
  @Suite("Validation Format Tests", .disabledOniOSWithXcode16_2OrOlder())
  internal struct ValidationFormatTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"
    private static let invalidAPIToken = "invalid_token_format"
    private static let shortWebAuthToken = "short"
    private static let emptyAPIToken = ""
    private static let emptyWebAuthToken = ""

    // MARK: - Token Format Validation Tests

    /// Tests validation with valid API token format
    @Test("Validation with valid API token format")
    internal func validAPITokenFormat() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    /// Tests validation with invalid API token format
    @Test("Validation with invalid API token format")
    internal func invalidAPITokenFormat() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.invalidAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
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

    /// Tests validation with short web auth token
    @Test("Validation with short web auth token")
    internal func shortWebAuthToken() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.shortWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
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

    /// Tests validation with empty API token
    @Test("Validation with empty API token")
    internal func emptyAPIToken() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.emptyAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
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

    /// Tests validation with empty web auth token
    @Test("Validation with empty web auth token")
    internal func emptyWebAuthToken() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.emptyWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
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
