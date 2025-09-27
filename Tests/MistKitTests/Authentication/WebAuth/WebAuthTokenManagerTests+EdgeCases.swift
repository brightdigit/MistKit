import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Edge case validation tests for WebAuthTokenManager
  @Suite("Validation Edge Case Tests")
  internal struct EdgeCases {
    // MARK: - Edge Case Validation Tests

    /// Tests validation with whitespace-only tokens
    @Test("Validation with whitespace only tokens")
    internal func whitespaceOnlyTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "   ",
        webAuthToken: "\t\n"
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

    /// Tests validation with special characters in tokens
    @Test("Validation with special characters in tokens")
    internal func specialCharactersInTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "api-token-with-special-chars!@#$%",
        webAuthToken: "web-token-with-special-chars!@#$%"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected - API token format is invalid
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests validation with very long tokens
    @Test("Validation with very long tokens")
    internal func veryLongTokens() async throws {
      let longAPIToken = String(repeating: "a", count: 1_000)
      let longWebAuthToken = String(repeating: "b", count: 1_000)

      let manager = WebAuthTokenManager(
        apiToken: longAPIToken,
        webAuthToken: longWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected - API token format is invalid (not 64 hex characters)
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
