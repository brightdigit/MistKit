internal import Foundation
internal import Testing

@testable import MistKit

extension APITokenManagerTests {
  /// Sendable compliance tests for APITokenManager.
  @Suite("API Token Manager Sendable")
  internal struct Metadata {
    // MARK: - Sendable Compliance Tests

    /// Tests that APITokenManager can be used across async boundaries.
    @Test("APITokenManager sendable compliance")
    internal func sendableCompliance() async {
      let validToken = TestConstants.apiToken
      let manager = APITokenManager(apiToken: validToken)

      async let task1 = manager.validateManager()
      async let task2 = manager.authenticatorFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
