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

  internal func validateCredentials() async throws -> Bool {
    throw TokenManagerError.authenticationFailed(underlying: nil)
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.authenticationFailed(underlying: nil)
  }
}
