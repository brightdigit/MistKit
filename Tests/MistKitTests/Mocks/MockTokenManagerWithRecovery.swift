//
//  MockTokenManagerWithRecovery.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

final class MockTokenManagerWithRecovery: TokenManager {
  private let counter = Counter()

  private actor Counter {
    private var count = 0

    func increment() -> Int {
      count += 1
      return count
    }
  }

  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    let count = await counter.increment()
    if count == 1 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "NetworkError", code: -1_009,
          userInfo: [
            NSLocalizedDescriptionKey: "Network error"
          ])
      )
    }
    return true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    if count == 1 {
      throw TokenManagerError.networkError(
        underlying: NSError(
          domain: "NetworkError", code: -1_009,
          userInfo: [
            NSLocalizedDescriptionKey: "Network error"
          ])
      )
    }
    return TokenCredentials.apiToken("recovered-token")
  }
}
