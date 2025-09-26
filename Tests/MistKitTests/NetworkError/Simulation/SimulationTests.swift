import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension NetworkErrorTests {
  /// Network error simulation tests
  @Suite("Simulation Tests")
  internal struct SimulationTests {
    // MARK: - Network Error Simulation Tests

    /// Tests simulation of network timeout errors
    @Test("Simulate network timeout errors")
    internal func simulateNetworkTimeoutErrors() async throws {
      let mockTokenManager = MockTokenManagerWithTimeout()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }

      do {
        _ = try await middleware.intercept(
          originalRequest,
          body: nil,
          baseURL: .cloudKitAPI,
          operationID: "test-operation",
          next: next
        )
        Issue.record("Should have thrown TokenManagerError.networkError")
      } catch let error as TokenManagerError {
        if case .networkError(let underlyingError) = error {
          #expect(underlyingError.localizedDescription.contains("Timeout"))
        } else {
          Issue.record("Expected networkError, got: \(error)")
        }
      }
    }

    /// Tests simulation of network connection errors
    @Test("Simulate network connection errors")
    internal func simulateNetworkConnectionErrors() async throws {
      let mockTokenManager = MockTokenManagerWithConnectionError()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }

      do {
        _ = try await middleware.intercept(
          originalRequest,
          body: nil,
          baseURL: .cloudKitAPI,
          operationID: "test-operation",
          next: next
        )
        Issue.record("Should have thrown TokenManagerError.networkError")
      } catch let error as TokenManagerError {
        if case .networkError(let underlyingError) = error {
          #expect(underlyingError.localizedDescription.contains("Connection"))
        } else {
          Issue.record("Expected networkError, got: \(error)")
        }
      }
    }

    /// Tests simulation of intermittent network failures
    @Test("Simulate intermittent network failures")
    internal func simulateIntermittentNetworkFailures() async throws {
      let mockTokenManager = MockTokenManagerWithIntermittentFailures()
      let middleware = AuthenticationMiddleware(tokenManager: mockTokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }

      var failureCount = 0
      var successCount = 0

      // Test multiple attempts to simulate intermittent failures
      for _ in 0..<10 {
        do {
          _ = try await middleware.intercept(
            originalRequest,
            body: nil,
            baseURL: .cloudKitAPI,
            operationID: "test-operation",
            next: next
          )
          successCount += 1
        } catch {
          failureCount += 1
        }
      }

      // Should have both successes and failures
      #expect(successCount > 0)
      #expect(failureCount > 0)
    }
  }
}
