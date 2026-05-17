//
//  MockTokenManagerWithTimeout.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates timeout
internal final class MockTokenManagerWithTimeout: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    throw TokenManagerError.networkError(.timeout)
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    throw TokenManagerError.networkError(.timeout)
  }
}
