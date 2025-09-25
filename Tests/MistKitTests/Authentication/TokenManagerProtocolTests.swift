import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Protocol Conformance")
/// Test suite for TokenManager protocol conformance and Sendable compliance
public struct TokenManagerProtocolTests {
  // MARK: - TokenManager Protocol Tests

  /// Tests TokenManager protocol conformance with mock implementation
  @Test("TokenManager protocol conformance with mock implementation")
  public func tokenManagerProtocolConformance() async throws {
    let mockManager = MockTokenManager()

    // Test protocol methods can be called
    let isValid = try await mockManager.validateCredentials()
    #expect(isValid == true)

    let credentials = try await mockManager.getCurrentCredentials()
    #expect(credentials != nil)

    // Test computed properties
    let hasCredentials = await mockManager.hasCredentials
    #expect(hasCredentials == true)
  }

  // MARK: - Sendable Compliance Tests

  /// Tests that all types are Sendable and can be used across async boundaries
  @Test("TokenManager sendable compliance")
  public func sendableCompliance() async {
    let method = AuthenticationMethod.apiToken("test")
    let credentials = TokenCredentials(method: method)
    let error = TokenManagerError.tokenExpired

    // Test concurrent access patterns
    async let task1 = credentials.processCredentials()
    async let task2 = method.processMethod()
    async let task3 = error.processError()

    let results = await (task1, task2, task3)
    #expect(results.0 == "api-token")
    #expect(results.1 == "api-token")
    #expect(results.2.isEmpty == false)
  }

}

// MARK: - Mock TokenManager Implementation

/// Mock implementation of TokenManager for testing protocol conformance
final class MockTokenManager: TokenManager {
  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    TokenCredentials.apiToken("mock-token")
  }
}
