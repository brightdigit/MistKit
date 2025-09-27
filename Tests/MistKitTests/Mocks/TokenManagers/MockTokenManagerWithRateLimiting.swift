//
//  MockTokenManagerWithRateLimiting.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

/// Mock TokenManager that simulates rate limiting
internal final class MockTokenManagerWithRateLimiting: TokenManager {
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
    // Simulate rate limiting - succeed after multiple attempts
    if count <= 3 {
      // Simulate rate limit delay
      do {
        try await Task.sleep(nanoseconds: 50_000_000)  // 0.05 seconds
      } catch {
        throw TokenManagerError.networkError(underlying: error)
      }
    }
    return true
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    let count = await counter.increment()
    // Simulate rate limiting - succeed after multiple attempts
    if count <= 3 {
      // Simulate rate limit delay
      do {
        try await Task.sleep(nanoseconds: 50_000_000)  // 0.05 seconds
      } catch {
        throw TokenManagerError.networkError(underlying: error)
      }
    }
    return TokenCredentials.apiToken("rate-limited-token")
  }
}
