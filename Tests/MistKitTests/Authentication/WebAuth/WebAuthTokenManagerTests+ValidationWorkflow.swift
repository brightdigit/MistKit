import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Integration validation tests for WebAuthTokenManager
  @Suite("Validation Workflow")
  internal struct ValidationWorkflow {
    // MARK: - Integration Tests

    /// Tests comprehensive validation workflow
    @Test("Comprehensive validation workflow")
    internal func comprehensiveValidationWorkflow() async throws {
      let validAPIToken =
        TestConstants.apiToken
      let validWebAuthToken = TestConstants.webAuthToken

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

      // Test currentAuthenticator
      let authenticator = try await manager.currentAuthenticator()
      let web = try #require(authenticator as? WebAuthTokenAuthenticator)
      #expect(web.apiToken == validAPIToken)
      #expect(web.webAuthToken == validWebAuthToken)
    }
  }
}
