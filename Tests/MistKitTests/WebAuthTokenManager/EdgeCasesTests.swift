import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Edge cases tests for WebAuthTokenManager
  @Suite("Edge Cases Tests")
  public struct EdgeCasesTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"

    // MARK: - Concurrent Access Edge Cases

    /// Tests concurrent access to WebAuthTokenManager
    @Test("Concurrent access to WebAuthTokenManager")
    public func concurrentAccessToWebAuthTokenManager() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Test concurrent access patterns
      async let task1 = Self.validateManager(manager)
      async let task2 = Self.getCredentialsFromManager(manager)
      async let task3 = Self.checkHasCredentials(manager)
      async let task4 = Self.validateManager(manager)
      async let task5 = Self.getCredentialsFromManager(manager)

      let results = await (task1, task2, task3, task4, task5)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
      #expect(results.3 == true)
      #expect(results.4 != nil)
    }

    /// Tests rapid successive calls to WebAuthTokenManager
    @Test("Rapid successive calls to WebAuthTokenManager")
    public func rapidSuccessiveCallsToWebAuthTokenManager() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Make rapid successive calls
      for _ in 0..<100 {
        let hasCredentials = await manager.hasCredentials
        #expect(hasCredentials == true)

        let isValid = try await manager.validateCredentials()
        #expect(isValid == true)

        let credentials = try await manager.getCurrentCredentials()
        #expect(credentials != nil)
      }
    }

    // MARK: - Memory Management Edge Cases

    /// Tests WebAuthTokenManager with weak references
    @Test("WebAuthTokenManager with weak references")
    public func webAuthTokenManagerWithWeakReferences() async throws {
      weak var weakManager: WebAuthTokenManager?

      do {
        let manager = WebAuthTokenManager(
          apiToken: Self.validAPIToken,
          webAuthToken: Self.validWebAuthToken
        )
        weakManager = manager

        let hasCredentials = await manager.hasCredentials
        #expect(hasCredentials == true)

        let isValid = try await manager.validateCredentials()
        #expect(isValid == true)
      }

      // Manager should be deallocated
      #expect(weakManager == nil)
    }

    /// Tests WebAuthTokenManager with storage cleanup
    @Test("WebAuthTokenManager with storage cleanup")
    public func webAuthTokenManagerWithStorageCleanup() async throws {
      let storage = InMemoryTokenStorage()
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken,
        storage: storage
      )

      // Store credentials
      let credentials = try await manager.getCurrentCredentials()
      #expect(credentials != nil)

      // Clear storage
      await storage.clear()

      // Manager should still work with its own tokens
      let hasCredentials = await manager.hasCredentials
      #expect(hasCredentials == true)

      let isValid = try await manager.validateCredentials()
      #expect(isValid == true)
    }

    // MARK: - Error Handling Edge Cases

    /// Tests WebAuthTokenManager with malformed tokens
    @Test("WebAuthTokenManager with malformed tokens")
    public func webAuthTokenManagerWithMalformedTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "malformed-api-token",
        webAuthToken: "malformed-web-token"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests WebAuthTokenManager with nil-like tokens
    @Test("WebAuthTokenManager with nil-like tokens")
    public func webAuthTokenManagerWithNilLikeTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "null",
        webAuthToken: "undefined"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch let error as TokenManagerError {
        if case .invalidCredentials = error {
          // Expected
        } else {
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

  }
}
