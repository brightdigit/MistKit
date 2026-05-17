import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension ConcurrentTokenRefreshTests {
  /// Test suite for concurrent token refresh performance functionality
  @Suite("Performance")
  internal struct Performance {
    // MARK: - Performance Scenario Tests

    /// Tests concurrent token refresh with rate limiting
    @Test("Concurrent token refresh with rate limiting")
    internal func concurrentTokenRefreshWithRateLimiting() async throws {
      let mockTokenManager = MockTokenManagerWithRateLimiting()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = ConcurrentTokenRefreshTests.makeRequest()
      let next = ConcurrentTokenRefreshTests.successNextHandler()
      let baseURL = CloudKitService.baseURL

      // Test concurrent access with rate limiting
      let results = await ConcurrentTokenRefreshTests.runConcurrent(
        middleware: middleware,
        request: request,
        baseURL: baseURL,
        next: next,
        count: 3
      )

      // All should succeed eventually due to rate limiting handling
      for result in results {
        #expect(result == true)
      }

      // Verify that refresh was called multiple times due to rate limiting
      #expect(await mockTokenManager.refreshCallCount >= 3)
    }
  }
}
