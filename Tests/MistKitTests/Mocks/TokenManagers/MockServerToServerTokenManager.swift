//
//  MockServerToServerTokenManager.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation

@testable import MistKit

/// Mock TokenManager that returns server-to-server credentials but isn't ServerToServerAuthManager
internal final class MockServerToServerTokenManager: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws(TokenManagerError) -> Bool {
    true
  }

  internal func getCurrentCredentials() async throws(TokenManagerError) -> TokenCredentials? {
    TokenCredentials.serverToServer(keyID: "test-key", privateKey: Data())
  }
}
