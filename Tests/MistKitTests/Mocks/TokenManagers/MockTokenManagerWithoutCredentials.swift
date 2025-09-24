//
//  MockTokenManagerWithoutCredentials.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//
@testable import MistKit

/// Mock TokenManager that returns no credentials
final class MockTokenManagerWithoutCredentials: TokenManager {
  var hasCredentials: Bool {
    get async { false }
  }

  func validateCredentials() async throws -> Bool {
    false
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    nil
  }
}
