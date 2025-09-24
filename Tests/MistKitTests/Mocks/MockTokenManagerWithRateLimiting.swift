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
final class MockTokenManagerWithRateLimiting: TokenManager {
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
    // Simulate rate limiting - succeed after multiple attempts
    if count <= 3 {
      // Simulate rate limit delay
      try await Task.sleep(nanoseconds: 50_000_000)  // 0.05 seconds
    }
    return true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    let count = await counter.increment()
    // Simulate rate limiting - succeed after multiple attempts
    if count <= 3 {
      // Simulate rate limit delay
      try await Task.sleep(nanoseconds: 50_000_000)  // 0.05 seconds
    }
    return TokenCredentials.apiToken("rate-limited-token")
  }
}
