//
//  MockTokenManagerWithConnectionError.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//
import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates connection errors
final class MockTokenManagerWithConnectionError: TokenManager {
  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "ConnectionError", code: -1_004,
        userInfo: [
          NSLocalizedDescriptionKey: "Connection failed"
        ])
    )
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "ConnectionError", code: -1_004,
        userInfo: [
          NSLocalizedDescriptionKey: "Connection failed"
        ])
    )
  }
}
