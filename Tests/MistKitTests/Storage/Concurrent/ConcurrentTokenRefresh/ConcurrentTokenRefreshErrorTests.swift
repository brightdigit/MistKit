import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Concurrent Token Refresh Error Tests")
/// Test suite for concurrent token refresh error handling functionality
internal struct ConcurrentTokenRefreshErrorTests {
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

  // MARK: - Error Scenario Tests

  /// Tests concurrent token refresh with refresh failures
  @Test("Concurrent token refresh with refresh failures")
  internal func concurrentTokenRefreshWithRefreshFailures() async throws {
    let mockTokenManager = MockTokenManagerWithRefreshFailure()
    let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

    let request = createTestRequest()
    let next = createSuccessNextHandler()
    let baseURL = URL.MistKit.cloudKitAPI

    // Test concurrent access with refresh failures
    let results = await executeConcurrentMiddlewareCalls(
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

    let request = createTestRequest()
    let next = createSuccessNextHandler()
    let baseURL = URL.MistKit.cloudKitAPI

    // Test concurrent access with timeout scenarios
    let results = await executeConcurrentMiddlewareCalls(
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
