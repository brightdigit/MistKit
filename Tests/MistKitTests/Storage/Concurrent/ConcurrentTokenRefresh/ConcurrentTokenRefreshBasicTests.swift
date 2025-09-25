import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Concurrent Token Refresh Basic Tests")
/// Test suite for basic concurrent token refresh functionality
internal struct ConcurrentTokenRefreshBasicTests {
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
  internal func concurrentTokenRefreshWithMultipleRequests() async throws {
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
  internal func concurrentTokenRefreshWithDifferentTokenManagers() async throws {
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
}
