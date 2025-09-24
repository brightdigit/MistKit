import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

// MARK: - Mock Token Managers for Concurrent Refresh Testing

/// Mock TokenManager that simulates refresh timeout
final class MockTokenManagerWithRefreshTimeout: TokenManager {
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
    // Simulate timeout on first call
    if count == 1 {
      try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
    }
    return true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    // Simulate timeout on first call
    if count == 1 {
      try await Task.sleep(nanoseconds: 2_000_000_000)  // 2 seconds
    }
    return TokenCredentials.apiToken("refreshed-token")
  }
}
