import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Network Error")
internal enum NetworkErrorTests {}

extension NetworkErrorTests {
  /// Network error recovery and retry mechanism tests
  @Suite("Recovery Tests")
  internal struct RecoveryTests {
    // MARK: - Error Recovery Tests

    /// Tests error recovery after network failure
    @Test("Error recovery after network failure")
    internal func errorRecoveryAfterNetworkFailure() async throws {
      let mockTokenManager = MockTokenManagerWithRecovery()
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

      // First call should fail with network error
      do {
        _ = try await middleware.intercept(
          originalRequest,
          body: nil,
          baseURL: URL.MistKit.cloudKitAPI,
          operationID: "test-operation",
          next: next
        )
        Issue.record("Should have thrown TokenManagerError.networkError")
      } catch let error as TokenManagerError {
        if case .networkError = error {
          // Expected
        } else {
          Issue.record("Expected networkError, got: \(error)")
        }
      }

      // Second call should succeed (recovery)
      let response = try await middleware.intercept(
        originalRequest,
        body: nil,
        baseURL: URL.MistKit.cloudKitAPI,
        operationID: "test-operation",
        next: next
      )

      #expect(response.0.status == .ok)
    }

    /// Tests retry mechanism with network failures
    @Test("Retry mechanism with network failures")
    internal func retryMechanismWithNetworkFailures() async throws {
      let mockTokenManager = MockTokenManagerWithRetry()
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

      // First two calls should fail, third should succeed
      var attemptCount = 0

      while attemptCount < 3 {
        do {
          let response = try await middleware.intercept(
            originalRequest,
            body: nil,
            baseURL: URL.MistKit.cloudKitAPI,
            operationID: "test-operation",
            next: next
          )
          #expect(response.0.status == .ok)
          break
        } catch let error as TokenManagerError {
          if case .networkError = error {
            attemptCount += 1
            if attemptCount < 3 {
              continue
            }
          }
          Issue.record("Unexpected error: \(error)")
        }
      }

      #expect(attemptCount == 2)  // Should have failed twice before succeeding
    }

    // MARK: - Timeout Handling Tests

    /// Tests timeout handling in token validation
    @Test("Timeout handling in token validation")
    internal func timeoutHandlingInTokenValidation() async throws {
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
          baseURL: URL.MistKit.cloudKitAPI,
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
  }
}
