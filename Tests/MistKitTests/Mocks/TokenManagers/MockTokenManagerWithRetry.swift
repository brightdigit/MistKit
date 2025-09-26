//
//  MockTokenManagerWithRetry.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates retry mechanism
internal final class MockTokenManagerWithRetry: TokenManager {
  private actor Counter {
    private var count = 0

    func increment() -> Int {
      count += 1
      return count
    }
  }

  private let counter = Counter()

  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    let count = await counter.increment()
    if count <= 2 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "NetworkError",
          code: -1_009,
          userInfo: [
            NSLocalizedDescriptionKey: "Network error"
          ]
        )
      )
    }
    return true
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    let count = await counter.increment()
    if count <= 2 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "NetworkError",
          code: -1_009,
          userInfo: [
            NSLocalizedDescriptionKey: "Network error"
          ]
        )
      )
    }
    return TokenCredentials.apiToken("retry-token")
  }
}
