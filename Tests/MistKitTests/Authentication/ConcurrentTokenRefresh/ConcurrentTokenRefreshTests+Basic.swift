internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension ConcurrentTokenRefreshTests {
  /// Test suite for basic concurrent token refresh functionality
  @Suite("Basic")
  internal struct Basic {
    // MARK: - Basic Concurrent Token Refresh Tests

    /// Tests concurrent token refresh with multiple requests
    @Test("Concurrent token refresh with multiple requests")
    internal func concurrentTokenRefreshWithMultipleRequests() async throws {
      let mockTokenManager = MockTokenManagerWithRefresh()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let request = ConcurrentTokenRefreshTests.makeRequest()
      let next = ConcurrentTokenRefreshTests.successNextHandler()
      let baseURL = CloudKitService.baseURL

      // Test concurrent access patterns
      let results = await ConcurrentTokenRefreshTests.runConcurrent(
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

      let request = ConcurrentTokenRefreshTests.makeRequest()
      let next = ConcurrentTokenRefreshTests.successNextHandler()
      let baseURL = CloudKitService.baseURL

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
      next:
        @escaping @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (
          HTTPResponse, HTTPBody?
        )
    ) async -> [Bool] {
      let tasks = middlewares.map { middleware in
        Task {
          await middleware.interceptWithMiddleware(
            request: request,
            baseURL: baseURL,
            operationID: TestConstants.operationID,
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
}
