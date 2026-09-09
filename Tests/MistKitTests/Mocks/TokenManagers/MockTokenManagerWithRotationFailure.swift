//
//  MockTokenManagerWithRotationFailure.swift
//  MistKit
//

internal import Foundation

@testable import MistKit

/// Mock TokenManager that fails when adopting a rotated web auth token.
internal final class MockTokenManagerWithRotationFailure: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    true
  }

  internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
    try APITokenAuthenticator(token: TestConstants.apiToken)
  }

  internal func didReceiveRotatedWebAuthToken(_ token: String) async throws(TokenManagerError) {
    throw TokenManagerError.invalidCredentials(.webAuthTokenTooShort)
  }
}
