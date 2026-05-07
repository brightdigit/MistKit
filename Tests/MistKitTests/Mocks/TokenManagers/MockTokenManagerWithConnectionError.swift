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
internal final class MockTokenManagerWithConnectionError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "ConnectionError",
        code: -1_004,
        userInfo: [
          NSLocalizedDescriptionKey: "Connection failed"
        ]
      )
    )
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "ConnectionError",
        code: -1_004,
        userInfo: [
          NSLocalizedDescriptionKey: "Connection failed"
        ]
      )
    )
  }
}
