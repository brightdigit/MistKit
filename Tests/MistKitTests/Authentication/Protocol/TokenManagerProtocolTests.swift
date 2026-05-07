import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Protocol Conformance")
/// Test suite for TokenManager protocol conformance and Sendable compliance
internal struct TokenManagerProtocolTests {
  // MARK: - TokenManager Protocol Tests

  /// Tests TokenManager protocol conformance with mock implementation
  @Test("TokenManager protocol conformance with mock implementation")
  internal func tokenManagerProtocolConformance() async throws {
    let mockManager = MockTokenManager()

    // Test protocol methods can be called
    let isValid = try await mockManager.validateCredentials()
    #expect(isValid == true)

    let authenticator = try await mockManager.currentAuthenticator()
    #expect(authenticator != nil)

    // Test computed properties
    let hasCredentials = await mockManager.hasCredentials
    #expect(hasCredentials == true)
  }

  // MARK: - Sendable Compliance Tests

  /// Tests that authenticators and errors are Sendable across async boundaries.
  @Test("TokenManager sendable compliance")
  internal func sendableCompliance() async throws {
    let authenticator = try APITokenAuthenticator(token: TestConstants.apiToken)
    let error = TokenManagerError.tokenExpired

    async let task1: String = {
      type(of: authenticator).storageKey
    }()
    async let task2 = error.processError()

    let results = await (task1, task2)
    #expect(results.0 == APITokenAuthenticator.storageKey)
    #expect(results.1.isEmpty == false)
  }
}
