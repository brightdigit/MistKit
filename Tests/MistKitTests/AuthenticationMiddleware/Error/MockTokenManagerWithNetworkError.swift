//
//  MockTokenManagerWithNetworkError.swift
//  MistKit
//
//  Created by Leo Dion on 9/25/25.
//

import Foundation

@testable import MistKit

/// Mock TokenManager that throws network error
internal final class MockTokenManagerWithNetworkError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "NetworkError",
        code: -1_009,
        userInfo: [NSLocalizedDescriptionKey: "Network error"]
      )
    )
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "NetworkError",
        code: -1_009,
        userInfo: [NSLocalizedDescriptionKey: "Network error"]
      )
    )
  }
}
