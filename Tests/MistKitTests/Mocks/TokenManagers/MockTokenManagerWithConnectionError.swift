//
//  MockTokenManagerWithConnectionError.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//
internal import Foundation
internal import Testing

@testable import MistKit

/// Mock TokenManager that simulates connection errors
internal final class MockTokenManagerWithConnectionError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    throw TokenManagerError.networkError(.notConnectedToInternet)
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    throw TokenManagerError.networkError(.notConnectedToInternet)
  }
}
