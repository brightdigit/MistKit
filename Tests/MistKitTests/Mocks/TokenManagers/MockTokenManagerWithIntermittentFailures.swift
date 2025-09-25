//
//  MockTokenManagerWithIntermittentFailures.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates intermittent failures
internal final class MockTokenManagerWithIntermittentFailures: TokenManager {
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

  internal func validateCredentials() async throws -> Bool {
    let count = await counter.increment()
    // Fail on odd attempts
    if count % 2 == 1 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "IntermittentError",
          code: -1_001,
          userInfo: [
            NSLocalizedDescriptionKey: "Intermittent network failure"
          ]
        )
      )
    }
    return true
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    // Fail on odd attempts
    if count % 2 == 1 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "IntermittentError",
          code: -1_001,
          userInfo: [
            NSLocalizedDescriptionKey: "Intermittent network failure"
          ]
        )
      )
    }
    return TokenCredentials.apiToken("intermittent-token")
  }
}
