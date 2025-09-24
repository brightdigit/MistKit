import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Error Handling")
/// Test suite for TokenManagerError and related functionality
public struct TokenManagerErrorTests {
  // MARK: - TokenManagerError Tests

  /// Tests TokenManagerError cases and localized descriptions
  @Test("TokenManagerError cases and localized descriptions")
  public func tokenManagerError() {
    let invalidError = TokenManagerError.invalidCredentials(reason: "Bad format")
    let authError = TokenManagerError.authenticationFailed(underlying: nil)
    let expiredError = TokenManagerError.tokenExpired
    let networkError = TokenManagerError.networkError(
      underlying: NSError(domain: "test", code: 123, userInfo: nil)
    )
    let internalError = TokenManagerError.internalError(reason: "System failure")

    // Test error descriptions
    #expect(invalidError.localizedDescription.contains("Invalid credentials"))
    #expect(invalidError.localizedDescription.contains("Bad format"))

    #expect(authError.localizedDescription.contains("Authentication failed"))

    #expect(expiredError.localizedDescription.contains("expired"))

    #expect(networkError.localizedDescription.contains("Network error"))

    #expect(internalError.localizedDescription.contains("Internal"))
    #expect(internalError.localizedDescription.contains("System failure"))
  }
}
