import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension ConcurrentTokenRefreshTests {
  /// Test suite for concurrent token refresh error handling functionality
  @Suite("Error")
  internal struct Error {
    // MARK: - Error Scenario Tests

    /// Tests concurrent token refresh with refresh failures
    @Test("Concurrent token refresh with refresh failures")
    internal func concurrentTokenRefreshWithRefreshFailures() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshFailure()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = ConcurrentTokenRefreshTests.makeRequest()
      let next = ConcurrentTokenRefreshTests.successNextHandler()
      let baseURL = CloudKitService.baseURL

      // Test concurrent access with refresh failures
      let results = await ConcurrentTokenRefreshTests.runConcurrent(
        middleware: middleware,
        request: request,
        baseURL: baseURL,
        next: next,
        count: 3
      )

      // At least one should fail due to refresh failure
      let hasFailure = results.contains(false)
      #expect(hasFailure)

      // Verify that refresh was attempted
      #expect(await mockTokenManager.refreshCallCount > 0)
    }

    /// Tests concurrent token refresh with timeout scenarios
    @Test("Concurrent token refresh with timeout scenarios")
    internal func concurrentTokenRefreshWithTimeoutScenarios() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshTimeout()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = ConcurrentTokenRefreshTests.makeRequest()
      let next = ConcurrentTokenRefreshTests.successNextHandler()
      let baseURL = CloudKitService.baseURL

      // Test concurrent access with timeout scenarios
      let results = await ConcurrentTokenRefreshTests.runConcurrent(
        middleware: middleware,
        request: request,
        baseURL: baseURL,
        next: next,
        count: 3
      )

      // Results may vary due to timeout, but at least one should complete
      let hasSuccess = results.contains(true)
      #expect(hasSuccess)

      // Verify that refresh was attempted
      #expect(await mockTokenManager.refreshCallCount > 0)
    }
  }
}
