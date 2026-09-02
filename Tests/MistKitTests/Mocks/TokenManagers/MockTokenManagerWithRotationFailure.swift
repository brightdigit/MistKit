//
//  MockTokenManagerWithRotationFailure.swift
//  MistKit
//

internal import Foundation

@testable import MistKit

/// Mock TokenManager that fails when adopting a rotated web auth token.

// Omitted on Windows × Swift 6.2: emit-module tip-over (see .claude/docs/research/windows-6.2-ci-failure-462.md).
#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
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

#endif
