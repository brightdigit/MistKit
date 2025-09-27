//
//  MockTokenManagerWithRefresh.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

/// Mock TokenManager that simulates token refresh
internal final class MockTokenManagerWithRefresh: TokenManager {
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
    // Simulate refresh on first call
    if count == 1 {
      // Simulate refresh delay
      do {
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      } catch {
        throw TokenManagerError.networkError(underlying: error)
      }
    }
    return true
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    let count = await counter.increment()
    // Simulate refresh on first call
    if count == 1 {
      // Simulate refresh delay
      do {
        try await Task.sleep(nanoseconds: 100_000_000)  // 0.1 seconds
      } catch {
        throw TokenManagerError.networkError(underlying: error)
      }
    }
    return TokenCredentials.apiToken("refreshed-token")
  }
}
