//
//  MockTokenManagerWithRefreshFailure.swift
//  Lint
//
//  Created by Leo Dion on 9/24/25.
//

internal import Foundation
internal import Testing

@testable import MistKit

/// Mock TokenManager that simulates refresh failure
internal final class MockTokenManagerWithRefreshFailure: TokenManager {
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

  private let counter = Counter()

  internal var hasCredentials: Bool {
    get async { true }
  }

  internal var refreshCallCount: Int {
    get async { await counter.getCount() }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    let count = await counter.increment()
    // Fail on odd calls
    if count % 2 == 1 {
      throw TokenManagerError.authenticationFailed(.serverRejected(statusCode: 401, message: nil))
    }
    return true
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    let count = await counter.increment()
    // Fail on odd calls
    if count % 2 == 1 {
      throw TokenManagerError.authenticationFailed(.serverRejected(statusCode: 401, message: nil))
    }
    return try APITokenAuthenticator(token: TestConstants.apiToken)
  }
}
