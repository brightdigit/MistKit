//
//  MockTokenManagerWithNetworkError.swift
//  MistKit
//
//  Created by Leo Dion on 9/25/25.
//

internal import Foundation

@testable import MistKit

/// Mock TokenManager that throws network error
internal final class MockTokenManagerWithNetworkError: TokenManager {
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
