import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Concurrent Token Refresh Performance Tests")
/// Test suite for concurrent token refresh performance functionality
internal struct ConcurrentTokenRefreshPerformanceTests {
  // MARK: - Helper Methods

  /// Creates a standard test request for concurrent token refresh tests
  private func createTestRequest() -> HTTPRequest {
    HTTPRequest(
      method: .get,
      scheme: "https",
      authority: "api.apple-cloudkit.com",
      path: "/database/1/iCloud.com.example.app/private/records/query"
    )
  }

  /// Creates a standard next handler that returns success
  private func createSuccessNextHandler() -> @Sendable (HTTPRequest, HTTPBody?, URL) async throws
    -> (HTTPResponse, HTTPBody?)
  {
    { _, _, _ in (HTTPResponse(status: .ok), nil) }
  }

  /// Creates a base URL for testing
  private func createBaseURL() -> URL {
    guard let url = URL(string: "https://api.apple-cloudkit.com") else {
      fatalError("Invalid URL")
    }
    return url
  }

  /// Executes concurrent middleware calls and returns results
  private func executeConcurrentMiddlewareCalls(
    middleware: AuthenticationMiddleware,
    request: HTTPRequest,
    baseURL: URL,
    next: @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
      HTTPResponse, HTTPBody?
    ),
    count: Int
  ) async -> [Bool] {
    let tasks = (1...count).map { _ in
      Task {
        await middleware.interceptWithMiddleware(
          request: request,
          baseURL: baseURL,
          operationID: "test-operation",
          next: next
        )
      }
    }

    return await withTaskGroup(of: Bool.self) { group in
      for task in tasks {
        group.addTask { await task.value }
      }

      var results: [Bool] = []
      for await result in group {
        results.append(result)
      }
      return results
    }
  }

  // MARK: - Performance Scenario Tests

  /// Tests concurrent token refresh with rate limiting
  @Test("Concurrent token refresh with rate limiting")
  internal func concurrentTokenRefreshWithRateLimiting() async throws {
    let mockTokenManager = MockTokenManagerWithRateLimiting()
    let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

    let request = createTestRequest()
    let next = createSuccessNextHandler()
    let baseURL = createBaseURL()

    // Test concurrent access with rate limiting
    let results = await executeConcurrentMiddlewareCalls(
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
