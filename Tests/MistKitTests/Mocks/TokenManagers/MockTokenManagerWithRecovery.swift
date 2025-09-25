//
//  MockTokenManagerWithRecovery.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

internal final class MockTokenManagerWithRecovery: TokenManager {
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
    if count == 1 {
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

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    if count == 1 {
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
    return TokenCredentials.apiToken("recovered-token")
  }
}
