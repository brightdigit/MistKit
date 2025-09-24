import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Edge case validation tests for WebAuthTokenManager
  @Suite("Validation Edge Case Tests")
  public struct ValidationEdgeCaseTests {
    // MARK: - Edge Case Validation Tests

    /// Tests validation with whitespace-only tokens
    @Test("Validation with whitespace only tokens")
    public func validationWithWhitespaceOnlyTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "   ",
        webAuthToken: "\t\n"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests validation with special characters in tokens
    @Test("Validation with special characters in tokens")
    public func validationWithSpecialCharactersInTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "api-token-with-special-chars!@#$%",
        webAuthToken: "web-token-with-special-chars!@#$%"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected - API token format is invalid
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests validation with very long tokens
    @Test("Validation with very long tokens")
    public func validationWithVeryLongTokens() async throws {
      let longAPIToken = String(repeating: "a", count: 1_000)
      let longWebAuthToken = String(repeating: "b", count: 1_000)

      let manager = WebAuthTokenManager(
        apiToken: longAPIToken,
        webAuthToken: longWebAuthToken
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected - API token format is invalid (not 64 hex characters)
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
