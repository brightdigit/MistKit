//
//  conformance.swift
//  MistKit
//
//  Created by Leo Dion on 9/25/25.
//

@testable import MistKit

/// Mock implementation of TokenManager for testing protocol conformance
internal final class MockTokenManager: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    true
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    try APITokenAuthenticator(token: TestConstants.apiToken)
  }
}
