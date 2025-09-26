import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

@Suite("Authentication Middleware - API Token", .disabledOniOSWithXcode16_2OrOlder())
/// API Token authentication tests for AuthenticationMiddleware
internal enum AuthenticationMiddlewareAPITokenTests {}

extension AuthenticationMiddlewareAPITokenTests {
  /// API Token authentication tests
  @Suite("API Token Tests", .disabledOniOSWithXcode16_2OrOlder())
  internal struct APITokenTests {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    private static let testURL: URL = {
      guard let url = URL(string: "https://api.apple-cloudkit.com") else {
        fatalError("Invalid URL")
      }
      return url
    }()
    private static let testOperationID = "test-operation"

    // MARK: - API Token Authentication Tests

    /// Tests intercept with API token authentication
    @Test("Intercept request with API token authentication")
    internal func interceptWithAPITokenAuthentication() async throws {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )

      var interceptedRequest: HTTPRequest?
      var interceptedBaseURL: URL?

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        request, _, baseURL in
        interceptedRequest = request
        interceptedBaseURL = baseURL
        return (HTTPResponse(status: .ok), nil)
      }

      _ = try await middleware.intercept(
        originalRequest,
        body: nil as HTTPBody?,
        baseURL: Self.testURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)
      #expect(interceptedBaseURL == Self.testURL)

      if let interceptedRequest = interceptedRequest {
        #expect(interceptedRequest.path?.contains("ckAPIToken=\(Self.validAPIToken)") == true)
      }
    }

    /// Tests intercept with API token authentication and existing query parameters
    @Test("Intercept request with API token and existing query parameters")
    internal func interceptWithAPITokenAuthenticationAndExistingQuery() async throws {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query?existingParam=value"
      )

      var interceptedRequest: HTTPRequest?

      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        request, _, _ in
        interceptedRequest = request
        return (HTTPResponse(status: .ok), nil)
      }

      _ = try await middleware.intercept(
        originalRequest,
        body: nil as HTTPBody?,
        baseURL: Self.testURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)

      if let interceptedRequest = interceptedRequest {
        let path = interceptedRequest.path ?? ""
        #expect(path.contains("existingParam=value"))
        #expect(path.contains("ckAPIToken=\(Self.validAPIToken)"))
      }
    }
  }
}
