import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Performance edge cases tests for WebAuthTokenManager
  @Suite("Edge Cases Performance Tests")
  public struct EdgeCasesPerformanceTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"

    // MARK: - Performance Edge Cases

    /// Tests WebAuthTokenManager performance with many operations
    @Test("WebAuthTokenManager performance with many operations")
    public func webAuthTokenManagerPerformanceWithManyOperations() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      let startTime = Date()

      // Perform many operations
      for _ in 0..<1_000 {
        let hasCredentials = await manager.hasCredentials
        #expect(hasCredentials == true)

        let isValid = try await manager.validateCredentials()
        #expect(isValid == true)
      }

      let endTime = Date()
      let duration = endTime.timeIntervalSince(startTime)

      // Should complete within reasonable time (adjust threshold as needed)
      #expect(duration < 10.0)  // 10 seconds should be more than enough
    }

    /// Tests WebAuthTokenManager with large token values
    @Test("WebAuthTokenManager with large token values")
    public func webAuthTokenManagerWithLargeTokenValues() async throws {
      let largeAPIToken = String(repeating: "a", count: 10_000)
      let largeWebAuthToken = String(repeating: "b", count: 10_000)

      let manager = WebAuthTokenManager(
        apiToken: largeAPIToken,
        webAuthToken: largeWebAuthToken
      )

      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == false)

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected - API token format is invalid (not 64 hex characters)
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }

      do {
        _ = try await manager.getCurrentCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected - API token format is invalid
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
