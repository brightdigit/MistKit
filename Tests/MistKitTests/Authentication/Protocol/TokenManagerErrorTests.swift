import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Error Handling", .serialized)
/// Test suite for TokenManagerError and related functionality
internal struct TokenManagerErrorTests {
  // MARK: - TokenManagerError Tests

  /// Tests TokenManagerError cases and localized descriptions
  @Test("TokenManagerError cases and localized descriptions")
  internal func tokenManagerError() {
    let invalidError = TokenManagerError.invalidCredentials(.apiTokenInvalidFormat)
    let authError = TokenManagerError.authenticationFailed(underlying: nil)
    let expiredError = TokenManagerError.tokenExpired
    let networkError = TokenManagerError.networkError(
      underlying: NSError(domain: "test", code: 123, userInfo: nil)
    )
    let internalError = TokenManagerError.internalError(.noCredentialsAvailable)

    // Test error descriptions
    #expect(invalidError.localizedDescription.contains("Invalid credentials"))
    #expect(invalidError.localizedDescription.contains("API token format is invalid"))

    #expect(authError.localizedDescription.contains("Authentication failed"))

    #expect(expiredError.localizedDescription.contains("expired"))

    #expect(networkError.localizedDescription.contains("Network error"))

    #expect(internalError.localizedDescription.contains("Internal"))
    #expect(internalError.localizedDescription.contains("No credentials available"))
  }
}
