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
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "TimeoutError",
        code: -1_001,
        userInfo: [
          NSLocalizedDescriptionKey: "Timeout"
        ]
      )
    )
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "TimeoutError",
        code: -1_001,
        userInfo: [
          NSLocalizedDescriptionKey: "Timeout"
        ]
      )
    )
  }
}
