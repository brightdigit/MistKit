//
//  MockTokenManagerWithRotation.swift
//  MistKit
//

internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime

@testable import MistKit

/// Mock TokenManager that records rotated web auth tokens from responses.

// Omitted on Windows × Swift 6.2: emit-module tip-over (see .claude/docs/research/windows-6.2-ci-failure-462.md).
#if !(os(Windows) && compiler(>=6.2) && compiler(<6.3))
  internal final class MockTokenManagerWithRotation: TokenManager {
    private actor State {
      private var receivedTokens: [String] = []

      func append(_ token: String) {
        receivedTokens.append(token)
      }

      func tokens() -> [String] {
        receivedTokens
      }
    }

    private let state = State()

    internal var hasCredentials: Bool {
      get async { true }
    }

    internal var receivedRotatedTokens: [String] {
      get async { await state.tokens() }
    }

    internal func validateCredentials() async throws(TokenManagerError) -> Bool {
      true
    }

    internal func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)? {
      try APITokenAuthenticator(token: TestConstants.apiToken)
    }

    internal func didReceiveRotatedWebAuthToken(_ token: String) async throws(TokenManagerError) {
      await state.append(token)
    }
  }

#endif
