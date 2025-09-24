//
//  MockTokenManagerWithRefreshFailure.swift
//  Lint
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates refresh failure
final class MockTokenManagerWithRefreshFailure: TokenManager {
  private let counter = Counter()

  private actor Counter {
    private var count = 0

    func increment() -> Int {
      count += 1
      return count
    }

    func getCount() -> Int {
      count
    }
  }

  var hasCredentials: Bool {
    get async { true }
  }

  var refreshCallCount: Int {
    get async { await counter.getCount() }
  }

  func validateCredentials() async throws -> Bool {
    let count = await counter.increment()
    // Fail on odd calls
    if count % 2 == 1 {
      throw TokenManagerError.authenticationFailed(underlying: nil)
    }
    return true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    // Fail on odd calls
    if count % 2 == 1 {
      throw TokenManagerError.authenticationFailed(underlying: nil)
    }
    return TokenCredentials.apiToken("refreshed-token")
  }
}
