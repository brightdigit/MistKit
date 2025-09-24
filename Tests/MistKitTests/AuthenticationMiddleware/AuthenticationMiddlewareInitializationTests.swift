import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Authentication Middleware Initialization")
/// Initialization tests for AuthenticationMiddleware
public enum AuthenticationMiddlewareInitializationTests {}

extension AuthenticationMiddlewareInitializationTests {
  /// Basic functionality tests for AuthenticationMiddleware
  @Suite("Basic Tests")
  public struct BasicTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let validWebAuthToken = "user123_web_auth_token_abcdef"
    private static let testURL: URL = {
      guard let url = URL(string: "https://api.apple-cloudkit.com") else {
        fatalError("Invalid URL")
      }
      return url
    }()
    private static let testOperationID = "test-operation"

    // MARK: - Initialization Tests

    /// Tests AuthenticationMiddleware initialization with APITokenManager
    @Test("Authentication Middleware initialization with API token manager")
    public func initializationWithAPITokenManager() {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      // Middleware should be initialized
      // Note: tokenManager is not optional, so we just verify it exists
      _ = middleware.tokenManager
    }

    /// Tests AuthenticationMiddleware initialization with WebAuthTokenManager
    @Test("Authentication Middleware initialization with web auth token manager")
    public func initializationWithWebAuthTokenManager() {
      let tokenManager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      // Middleware should be initialized
      // Note: tokenManager is not optional, so we just verify it exists
      _ = middleware.tokenManager
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that AuthenticationMiddleware can be used across async boundaries
    @Test("Authentication Middleware sendable compliance")
    public func sendableCompliance() async throws {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      // Test concurrent access patterns with separate closures
      async let task1 = middleware.interceptWithMiddleware(
        request: originalRequest,
        baseURL: Self.testURL,
        operationID: Self.testOperationID
      ) { _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }
      async let task2 = middleware.interceptWithMiddleware(
        request: originalRequest,
        baseURL: Self.testURL,
        operationID: Self.testOperationID
      ) { _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }
      async let task3 = middleware.interceptWithMiddleware(
        request: originalRequest,
        baseURL: Self.testURL,
        operationID: Self.testOperationID
      ) { _, _, _ in
        (HTTPResponse(status: .ok), nil)
      }

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 == true)
      #expect(results.2 == true)
    }
  }
}
