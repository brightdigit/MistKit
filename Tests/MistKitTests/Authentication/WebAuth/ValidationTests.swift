import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Integration validation tests for WebAuthTokenManager
  @Suite("Validation Tests")
  internal struct ValidationTests {
    // MARK: - Integration Tests

    /// Tests comprehensive validation workflow
    @Test("Comprehensive validation workflow")
    internal func comprehensiveValidationWorkflow() async throws {
      let validAPIToken =
        "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
      let validWebAuthToken = "user123_web_auth_token_abcdef"

      let manager = WebAuthTokenManager(
        apiToken: validAPIToken,
        webAuthToken: validWebAuthToken
      )

      // Test hasCredentials
      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)

      // Test validateCredentials
      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)

      // Test getCurrentCredentials
      let credentials = try await manager.getCurrentCredentials()
      #expect(credentials != nil)

      if let credentials = credentials {
        if case .webAuthToken(let api, let web) = credentials.method {
          #expect(api == validAPIToken)
          #expect(web == validWebAuthToken)
        } else {
          Issue.record("Expected .webAuthToken method")
        }
      }
    }
  }
}
