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

  internal func validateCredentials() async throws -> Bool {
    true
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    TokenCredentials.serverToServer(keyID: "test-key", privateKey: Data())
  }
}
