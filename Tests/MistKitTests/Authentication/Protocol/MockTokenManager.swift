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

  internal func validateCredentials() async throws -> Bool {
    true
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    TokenCredentials.apiToken("mock-token")
  }
}
