import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager")
/// Test suite for TokenManager protocol and related types
internal struct TokenManagerTests {
  // MARK: - Integration Tests

  /// Tests integration between different TokenManager components
  @Test("TokenManager integration test")
  internal func tokenManagerIntegration() async throws {
    let mockManager = MockTokenManager()

    let isValid = try await mockManager.validateCredentials()
    #expect(isValid == true)

    let authenticator = try await mockManager.currentAuthenticator()
    let api = try #require(authenticator as? APITokenAuthenticator)
    #expect(type(of: api).storageKey == APITokenAuthenticator.storageKey)
  }
}
