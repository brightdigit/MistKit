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
    // MARK: - Concurrent Token Refresh Tests

    /// Tests concurrent token refresh with multiple requests
    @Test("Concurrent token refresh with multiple requests")
    public func concurrentTokenRefreshWithMultipleRequests() async throws {
      let mockTokenManager = MockTokenManagerWithRefresh()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) =
        {
          _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }

      // Test concurrent access patterns
      async let task1 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task2 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task3 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task4 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task5 = Self.interceptWithMiddleware(middleware, originalRequest, next)

      let results = await (task1, task2, task3, task4, task5)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)
      #expect(results.3 == true)
      #expect(results.4 == true)

      // Verify that refresh was called for each concurrent request
      #expect(await mockTokenManager.refreshCallCount == 5)
    }

    /// Tests concurrent token refresh with different token managers
    @Test("Concurrent token refresh with different token managers")
    public func concurrentTokenRefreshWithDifferentTokenManagers() async throws {
      let mockTokenManager1 = MockTokenManagerWithRefresh()
      let mockTokenManager2 = MockTokenManagerWithRefresh()
      let mockTokenManager3 = MockTokenManagerWithRefresh()

      let middleware1 = AuthenticationMiddleware(tokenManager: mockTokenManager1)
      let middleware2 = AuthenticationMiddleware(tokenManager: mockTokenManager2)
      let middleware3 = AuthenticationMiddleware(tokenManager: mockTokenManager3)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) =
        {
          _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }

      // Test concurrent access with different middlewares
      async let task1 = Self.interceptWithMiddleware(middleware1, originalRequest, next)
      async let task2 = Self.interceptWithMiddleware(middleware2, originalRequest, next)
      async let task3 = Self.interceptWithMiddleware(middleware3, originalRequest, next)

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      // Each token manager should have refreshed once
      #expect(await mockTokenManager1.refreshCallCount == 1)
      #expect(await mockTokenManager2.refreshCallCount == 1)
      #expect(await mockTokenManager3.refreshCallCount == 1)
    }

    /// Tests concurrent token refresh with refresh failures
    @Test("Concurrent token refresh with refresh failures")
    public func concurrentTokenRefreshWithRefreshFailures() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshFailure()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) =
        {
          _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }

      // Test concurrent access with refresh failures
      async let task1 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task2 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task3 = Self.interceptWithMiddleware(middleware, originalRequest, next)

      let results = await (task1, task2, task3)

      // At least one should fail due to refresh failure
      let hasFailure = !results.0 || !results.1 || !results.2
      #expect(hasFailure)

      // Verify that refresh was attempted
      #expect(await mockTokenManager.refreshCallCount > 0)
    }

    /// Tests concurrent token refresh with timeout scenarios
    @Test("Concurrent token refresh with timeout scenarios")
    public func concurrentTokenRefreshWithTimeoutScenarios() async throws {
      let mockTokenManager = MockTokenManagerWithRefreshTimeout()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) =
        {
          _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }

      // Test concurrent access with timeout scenarios
      async let task1 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task2 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task3 = Self.interceptWithMiddleware(middleware, originalRequest, next)

      let results = await (task1, task2, task3)

      // Results may vary due to timeout, but at least one should complete
      let hasSuccess = results.0 || results.1 || results.2
      #expect(hasSuccess)

      // Verify that refresh was attempted
      #expect(await mockTokenManager.refreshCallCount > 0)
    }

    /// Tests concurrent token refresh with rate limiting
    @Test("Concurrent token refresh with rate limiting")
    public func concurrentTokenRefreshWithRateLimiting() async throws {
      let mockTokenManager = MockTokenManagerWithRateLimiting()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) =
        {
          _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }

      // Test concurrent access with rate limiting
      async let task1 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task2 = Self.interceptWithMiddleware(middleware, originalRequest, next)
      async let task3 = Self.interceptWithMiddleware(middleware, originalRequest, next)

      let results = await (task1, task2, task3)

      // All should succeed eventually due to rate limiting handling
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)

      // Verify that refresh was called multiple times due to rate limiting
      #expect(await mockTokenManager.refreshCallCount >= 3)
    }

    // MARK: - Helper Methods

    private static func interceptWithMiddleware(
      _ middleware: AuthenticationMiddleware,
      _ request: HTTPRequest,
      _ next: @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
        HTTPResponse, HTTPBody?
      )
    ) async -> Bool {
      do {
        _ = try await middleware.intercept(
          request,
          body: nil as HTTPBody?,
          baseURL: {
            guard let url = URL(string: "https://api.apple-cloudkit.com") else {
              fatalError("Invalid URL")
            }
            return url
          }(),
          operationID: "test-operation",
          next: next
        )
        return true
      } catch {
        return false
      }
    }
  }
}
