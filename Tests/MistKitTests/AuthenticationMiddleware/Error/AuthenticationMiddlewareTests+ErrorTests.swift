import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension AuthenticationMiddlewareTests {
  /// Error handling tests for AuthenticationMiddleware
  @Suite("Error Tests", .enabled(if: Platform.isCryptoAvailable))
  internal struct ErrorTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let testOperationID = "test-operation"

    // MARK: - Token Validation Error Tests

    /// Tests intercept with invalid token manager
    @Test("Intercept request with invalid token manager")
    internal func interceptWithInvalidTokenManager() async throws {
      let mockTokenManager = MockTokenManagerWithoutCredentials()
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
          body: nil as HTTPBody?,
          baseURL: URL.MistKit.cloudKitAPI,
          operationID: Self.testOperationID,
          next: next
        )
        Issue.record("Should have thrown TokenManagerError.invalidCredentials")
      } catch {
        switch error {
        case TokenManagerError.invalidCredentials(_):
          // Expected
          break
        default:
          Issue.record("Expected invalidCredentials error, got: \(error)")
        }
      }
    }

    /// Tests intercept with token manager that throws authentication error
    @Test("Intercept request with token manager that throws authentication error")
    internal func interceptWithTokenManagerAuthenticationError() async throws {
      let mockTokenManager = MockTokenManagerWithAuthenticationError()
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
          body: nil as HTTPBody?,
          baseURL: URL.MistKit.cloudKitAPI,
          operationID: Self.testOperationID,
          next: next
        )
        Issue.record("Should have thrown TokenManagerError.authenticationFailed")
      } catch let error as TokenManagerError {
        if case .authenticationFailed = error {
          // Expected
        } else {
          Issue.record("Expected authenticationFailed error, got: \(error)")
        }
      }
    }

    /// Tests intercept with token manager that throws network error
    @Test("Intercept request with token manager that throws network error")
    internal func interceptWithTokenManagerNetworkError() async throws {
      let mockTokenManager = MockTokenManagerWithNetworkError()
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
          body: nil as HTTPBody?,
          baseURL: URL.MistKit.cloudKitAPI,
          operationID: Self.testOperationID,
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
    }

    /// Tests that errors from next middleware are properly propagated
    @Test("Error propagation from next middleware")
    internal func errorPropagationFromNextMiddleware() async throws {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        _, _, _ in
        throw NSError(
          domain: "TestError",
          code: 500,
          userInfo: [
            NSLocalizedDescriptionKey: "Test error from next middleware"
          ]
        )
      }

      do {
        _ = try await middleware.intercept(
          originalRequest,
          body: nil as HTTPBody?,
          baseURL: URL.MistKit.cloudKitAPI,
          operationID: Self.testOperationID,
          next: next
        )
        Issue.record("Should have thrown error from next middleware")
      } catch let error as NSError {
        #expect(error.domain == "TestError")
        #expect(error.code == 500)
        #expect(error.localizedDescription == "Test error from next middleware")
      }
    }
  }
}

// MARK: - Mock Token Managers for Error Testing
