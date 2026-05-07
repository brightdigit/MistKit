//
//  MockTokenManagerWithAuthenticationError.swift
//  MistKit
//
//  Created by Leo Dion on 9/25/25.
//

@testable import MistKit

/// Mock TokenManager that throws authentication failed error
internal final class MockTokenManagerWithAuthenticationError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    throw TokenManagerError.authenticationFailed(.unknown)
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    throw TokenManagerError.authenticationFailed(.unknown)
  }
}
