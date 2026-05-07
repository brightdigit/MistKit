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

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    let count = await counter.increment()
    // Fail on odd attempts
    if count % 2 == 1 {
      throw TokenManagerError.networkError(.timeout)
    }
    return true
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    let count = await counter.increment()
    // Fail on odd attempts
    if count % 2 == 1 {
      throw TokenManagerError.networkError(.timeout)
    }
    return try APITokenAuthenticator(token: TestConstants.apiToken)
  }
}
