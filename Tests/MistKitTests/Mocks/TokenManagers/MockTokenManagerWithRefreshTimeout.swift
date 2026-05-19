internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

// MARK: - Mock Token Managers for Concurrent Refresh Testing

/// Mock TokenManager that simulates refresh timeout
internal final class MockTokenManagerWithRefreshTimeout: TokenManager {
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
    // Simulate timeout on first call
    if count == 1 {
      do {
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
      } catch {
        throw TokenManagerError.networkError(.other(error))
      }
    }
    return true
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    let count = await counter.increment()
    // Simulate timeout on first call
    if count == 1 {
      do {
        try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
      } catch {
        throw TokenManagerError.networkError(.other(error))
      }
    }
    return try APITokenAuthenticator(token: TestConstants.apiToken)
  }
}
