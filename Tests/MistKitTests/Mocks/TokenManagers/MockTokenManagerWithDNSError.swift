import Foundation
import Testing

@testable import MistKit

// MARK: - Mock Token Managers for Simulation

/// Mock TokenManager that simulates DNS resolution errors
internal final class MockTokenManagerWithDNSError: TokenManager {
  internal var hasCredentials: Bool {
    get async { true }
  }

  internal func validateCredentials() async throws -> Bool {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "DNSError",
        code: -1_002,
        userInfo: [
          NSLocalizedDescriptionKey: "DNS resolution failed"
        ]
      )
    )
  }

  internal func getCurrentCredentials() async throws -> TokenCredentials? {
    throw TokenManagerError.networkError(
      underlying: NSError(
        domain: "DNSError",
        code: -1_002,
        userInfo: [
          NSLocalizedDescriptionKey: "DNS resolution failed"
        ]
      )
    )
  }
}
