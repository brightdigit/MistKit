//
//  MockServerToServerTokenManager.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation

@testable import MistKit

/// Mock TokenManager that returns server-to-server credentials but isn't ServerToServerAuthManager
final class MockServerToServerTokenManager: TokenManager {
  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    TokenCredentials.serverToServer(keyID: "test-key", privateKey: Data())
  }
}
