import XCTest

@testable import MistKit

internal final class AdaptiveTokenManagerIntegrationTests: XCTestCase {
  func testAdaptiveTokenManagerTransitions() async throws {
    // Create adaptive manager starting with API-only authentication
    let apiToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

    // Test initial API-only state
    let initialCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .apiToken(let token) = initialCredentials?.method {
      XCTAssertEqual(token, apiToken)
    } else {
      XCTFail("Expected .apiToken method")
    }

    // Test upgrade to web authentication
    let webToken = "user123_web_auth_token"
    let upgradedCredentials = try await adaptiveManager.upgradeToWebAuthentication(
      webAuthToken: webToken
    )
    if case .webAuthToken(let api, let web) = upgradedCredentials.method {
      XCTAssertEqual(api, apiToken)
      XCTAssertEqual(web, webToken)
    } else {
      XCTFail("Expected .webAuthToken method")
    }

    // Verify state after upgrade
    let currentCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .webAuthToken(_, let web) = currentCredentials?.method {
      XCTAssertEqual(web, webToken)
    } else {
      XCTFail("Expected .webAuthToken method")
    }

    // Test downgrade back to API-only
    let downgradedCredentials = try await adaptiveManager.downgradeToAPIOnly()
    if case .apiToken(let token) = downgradedCredentials.method {
      XCTAssertEqual(token, apiToken)
    } else {
      XCTFail("Expected .apiToken method")
    }

    // Verify final state
    let finalCredentials = try await adaptiveManager.getCurrentCredentials()
    if case .apiToken = finalCredentials?.method {
      // Success - back to API token
    } else {
      XCTFail("Expected .apiToken method")
    }

    // Test that manager still validates credentials properly
    let isValid = try await adaptiveManager.validateCredentials()
    XCTAssertTrue(isValid)
  }

  func testAdaptiveTokenManagerProperties() async throws {
    let apiToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let adaptiveManager = AdaptiveTokenManager(apiToken: apiToken)

    // Test initial properties
    let supportsRefresh = adaptiveManager.supportsRefresh
    XCTAssertFalse(supportsRefresh)
    let hasCredentials = await adaptiveManager.hasCredentials
    XCTAssertTrue(hasCredentials)

    // Test that refresh throws appropriate error
    do {
      _ = try await adaptiveManager.refreshCredentials()
      XCTFail("Should have thrown refreshNotSupported error")
    } catch let error as TokenManagerError {
      if case .refreshNotSupported = error {
        // Success - correct error type
      } else {
        XCTFail("Expected refreshNotSupported error, got: \(error)")
      }
    }
  }

  func testAdaptiveTokenManagerWithInvalidToken() async throws {
    let invalidApiToken = "invalid_token"
    let adaptiveManager = AdaptiveTokenManager(apiToken: invalidApiToken)

    // Should fail validation with invalid token format
    do {
      _ = try await adaptiveManager.validateCredentials()
      XCTFail("Should have thrown invalidCredentials error")
    } catch let error as TokenManagerError {
      if case .invalidCredentials(let reason) = error {
        XCTAssertEqual(reason, "API token format is invalid")
      } else {
        XCTFail("Expected invalidCredentials error, got: \(error)")
      }
    }
  }
}
