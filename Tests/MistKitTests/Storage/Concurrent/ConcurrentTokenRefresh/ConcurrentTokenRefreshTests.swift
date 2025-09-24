import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Concurrent Token Refresh")
public enum ConcurrentTokenRefreshTests {}

extension ConcurrentTokenRefreshTests {
  /// Tests for concurrent token refresh functionality
  @Suite("Tests")
  public struct Tests {
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

    // MARK: - Basic Concurrent Token Refresh Tests

    /// Tests concurrent token refresh with multiple requests
    @Test("Concurrent token refresh with multiple requests")
    public func concurrentTokenRefreshWithMultipleRequests() async throws {
      let mockTokenManager = MockTokenManagerWithRefresh()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = createTestRequest()
      let next = createSuccessNextHandler()
      let baseURL = createBaseURL()

      // Test concurrent access patterns
      let results = await executeConcurrentMiddlewareCalls(
        middleware: middleware,
        request: request,
        baseURL: baseURL,
        next: next,
        count: 5
      )

      // Verify all requests succeeded
      for result in results {
        #expect(result == true)
      }

      // Verify that refresh was called for each concurrent request
      #expect(await mockTokenManager.refreshCallCount == 5)
    }

    /// Tests concurrent token refresh with different token managers
    @Test("Concurrent token refresh with different token managers")
    public func concurrentTokenRefreshWithDifferentTokenManagers() async throws {
      let tokenManagers = [
        MockTokenManagerWithRefresh(),
        MockTokenManagerWithRefresh(),
        MockTokenManagerWithRefresh(),
      ]

      let middlewares = tokenManagers.map { AuthenticationMiddleware(tokenManager: $0) }

      let request = createTestRequest()
      let next = createSuccessNextHandler()
      let baseURL = createBaseURL()

      // Test concurrent access with different middlewares
      let results = await executeConcurrentMiddlewareCallsWithDifferentMiddlewares(
        middlewares: middlewares,
        request: request,
        baseURL: baseURL,
        next: next
      )

      // Verify all requests succeeded
      for result in results {
        #expect(result == true)
      }

      // Each token manager should have refreshed once
      for tokenManager in tokenManagers {
        #expect(await tokenManager.refreshCallCount == 1)
      }
    }

    /// Executes concurrent middleware calls with different middlewares
    private func executeConcurrentMiddlewareCallsWithDifferentMiddlewares(
      middlewares: [AuthenticationMiddleware],
      request: HTTPRequest,
      baseURL: URL,
      next: @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
        HTTPResponse, HTTPBody?
      )
    ) async -> [Bool] {
      let tasks = middlewares.map { middleware in
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
    public func concurrentTokenRefreshWithRefreshFailures() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshFailure()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = createTestRequest()
      let next = createSuccessNextHandler()
      let baseURL = createBaseURL()

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
    public func concurrentTokenRefreshWithTimeoutScenarios() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshTimeout()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = createTestRequest()
      let next = createSuccessNextHandler()
      let baseURL = createBaseURL()

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

    // MARK: - Performance Scenario Tests

    /// Tests concurrent token refresh with rate limiting
    @Test("Concurrent token refresh with rate limiting")
    public func concurrentTokenRefreshWithRateLimiting() async throws {
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
}
