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
final class MockTokenManagerWithTimeout: TokenManager {
  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "TimeoutError", code: -1_001,
        userInfo: [
          NSLocalizedDescriptionKey: "Timeout"
        ])
    )
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "TimeoutError", code: -1_001,
        userInfo: [
          NSLocalizedDescriptionKey: "Timeout"
        ])
    )
  }
}
