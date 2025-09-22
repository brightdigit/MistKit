import Testing

@testable import MistKit

struct AdaptiveTokenManagerIntegrationTests {
  @Test
  func adaptiveTokenManagerTransitions() async throws {
    // Create adaptive manager starting with API-only authentication
    let apiToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

    // Test initial API-only state
    let initialCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .apiToken(let token) = initialCredentials?.method {
      #expect(token == apiToken)
    } else {
      Issue.record("Expected .apiToken method")
    }

    // Test upgrade to web authentication
    let webToken = "user123_web_auth_token"
    let upgradedCredentials = try await adaptiveManager.upgradeToWebAuthentication(
      webAuthToken: webToken
    )
    if case .webAuthToken(let api, let web) = upgradedCredentials.method {
      #expect(api == apiToken)
      #expect(web == webToken)
    } else {
      Issue.record("Expected .webAuthToken method")
    }

    // Verify state after upgrade
    let currentCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .webAuthToken(_, let web) = currentCredentials?.method {
      #expect(web == webToken)
    } else {
      Issue.record("Expected .webAuthToken method")
    }

    // Test downgrade back to API-only
    let downgradedCredentials = try await adaptiveManager.downgradeToAPIOnly()
    if case .apiToken(let token) = downgradedCredentials.method {
      #expect(token == apiToken)
    } else {
      Issue.record("Expected .apiToken method")
    }

    // Verify final state
    let finalCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .apiToken = finalCredentials?.method {
      // Success - back to API token
    } else {
      Issue.record("Expected .apiToken method")
    }

    // Test that manager still validates credentials properly
    let isValid = try await adaptiveManager.validateCredentials()
    #expect(isValid == true)
  }

  @Test
  func adaptiveTokenManagerProperties() async throws {
    let apiToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

    // Test initial properties
    let hasCredentials = await adaptiveManager.hasCredentials
    #expect(hasCredentials == true)
  }

  @Test
  func adaptiveTokenManagerWithInvalidToken() async throws {
    let invalidApiToken = "invalid_token"
    let adaptiveManager = AdaptiveTokenManager(apiToken: invalidApiToken)

    // Should fail validation with invalid token format
    do {
      _ = try await adaptiveManager.validateCredentials()
      Issue.record("Should have thrown invalidCredentials error")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(let reason) = error {
        #expect(reason == "API token format is invalid (expected 64-character hex string)")
      } else {
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }
}
