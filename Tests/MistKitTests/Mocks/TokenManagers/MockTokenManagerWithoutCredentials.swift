//
//  MockTokenManagerWithoutCredentials.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//
@testable import MistKit

/// Mock TokenManager that returns no credentials
internal final class MockTokenManagerWithoutCredentials: TokenManager {
  internal var hasCredentials: Bool {
    get async { false }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    false
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    nil
  }
}
