//
//  MockTokenManagerWithSSLError.swift
//  MistKit
//
//  Created by Leo Dion on 9/24/25.
//

import Foundation
import Testing

@testable import MistKit

/// Mock TokenManager that simulates SSL/TLS errors
internal final class MockTokenManagerWithSSLError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "SSLError",
        code: -1_003,
        userInfo: [
          NSLocalizedDescriptionKey: "SSL/TLS handshake failed"
        ]
      )
    )
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "SSLError",
        code: -1_003,
        userInfo: [
          NSLocalizedDescriptionKey: "SSL/TLS handshake failed"
        ]
      )
    )
  }
}
