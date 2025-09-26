import Foundation
import Testing

@testable import MistKit

extension WebAuthTokenManagerTests {
  /// Edge cases tests for WebAuthTokenManager
  @Suite("Edge Cases Tests")
  internal struct EdgeCasesTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"

    // MARK: - Concurrent Access Edge Cases

    /// Tests concurrent access to WebAuthTokenManager
    @Test("Concurrent access to WebAuthTokenManager")
    internal func concurrentAccessToWebAuthTokenManager() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Test concurrent access patterns
      async let task1 = manager.validateManager()
      async let task2 = manager.getCredentialsFromManager()
      async let task3 = manager.checkHasCredentials()
      async let task4 = manager.validateManager()
      async let task5 = manager.getCredentialsFromManager()

      let results = await (task1, task2, task3, task4, task5)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
      #expect(results.3 == true)
      #expect(results.4 != nil)
    }

    /// Tests rapid successive calls to WebAuthTokenManager
    @Test("Rapid successive calls to WebAuthTokenManager")
    internal func rapidSuccessiveCallsToWebAuthTokenManager() async throws {
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )

      // Make rapid successive calls
      for _ in 0..<100 {
        let hasCredentials = await manager.checkHasCredentials()
        #expect(hasCredentials == true)

        let isValid = await manager.validateManager()
        #expect(isValid == true)

        let credentials = await manager.getCredentialsFromManager()
        #expect(credentials != nil)
      }
    }

    // MARK: - Memory Management Edge Cases

    /// Tests WebAuthTokenManager with weak references
    @Test("WebAuthTokenManager with weak references")
    internal func webAuthTokenManagerWithWeakReferences() async throws {
      weak var weakManager: WebAuthTokenManager?

      do {
        let manager = WebAuthTokenManager(
          apiToken: Self.validAPIToken,
          webAuthToken: Self.validWebAuthToken
        )
        weakManager = manager

        let hasCredentials = await manager.checkHasCredentials()
        #expect(hasCredentials == true)

        let isValid = await manager.validateManager()
        #expect(isValid == true)
      }

      // Manager should be deallocated
      #expect(weakManager == nil)
    }

    /// Tests WebAuthTokenManager with storage cleanup
    @Test("WebAuthTokenManager with storage cleanup")
    internal func webAuthTokenManagerWithStorageCleanup() async throws {
      let storage = InMemoryTokenStorage()
      let manager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken,
        storage: storage
      )

      // Store credentials
      let credentials = await manager.getCredentialsFromManager()
      #expect(credentials != nil)

      // Clear storage
      await storage.clear()

      // Manager should still work with its own tokens
      let hasCredentials = await manager.checkHasCredentials()
      #expect(hasCredentials == true)

      let isValid = await manager.validateManager()
      #expect(isValid == true)
    }

    // MARK: - Error Handling Edge Cases

    /// Tests WebAuthTokenManager with malformed tokens
    @Test("WebAuthTokenManager with malformed tokens")
    internal func malformedTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "malformed-api-token",
        webAuthToken: "malformed-web-token"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests WebAuthTokenManager with nil-like tokens
    @Test("WebAuthTokenManager with nil-like tokens")
    internal func webAuthTokenManagerWithNilLikeTokens() async throws {
      let manager = WebAuthTokenManager(
        apiToken: "null",
        webAuthToken: "undefined"
      )

      do {
        _ = try await manager.validateCredentials()
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }
  }
}
