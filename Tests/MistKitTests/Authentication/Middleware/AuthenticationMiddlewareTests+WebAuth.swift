import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

extension AuthenticationMiddlewareTests {
  /// Web Auth Token authentication tests
  @Suite("Web Auth Token")
  internal struct WebAuthToken {
    // MARK: - Test Data Setup

    private static let validAPIToken =
      TestConstants.apiToken
    private static let validWebAuthToken = TestConstants.webAuthToken
    private static let testOperationID = TestConstants.operationID

    // MARK: - Web Auth Token Authentication Tests

    /// Tests intercept with web auth token authentication
    @Test("Intercept request with web auth token authentication")
    internal func interceptWithWebAuthTokenAuthentication() async throws {
      let tokenManager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
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
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)

      if let interceptedRequest = interceptedRequest {
        let path = interceptedRequest.path ?? ""
        #expect(path.contains("ckAPIToken=\(Self.validAPIToken)"))
        #expect(path.contains("ckWebAuthToken="))
      }
    }

    /// Tests intercept with web auth token authentication and existing query parameters
    @Test("Intercept request with web auth token and existing query parameters")
    internal func interceptWithWebAuthTokenAuthenticationAndExistingQuery() async throws {
      let tokenManager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )
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
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)

      if let interceptedRequest = interceptedRequest {
        let path = interceptedRequest.path ?? ""
        #expect(path.contains("existingParam=value"))
        #expect(path.contains("ckAPIToken=\(Self.validAPIToken)"))
        #expect(path.contains("ckWebAuthToken="))
      }
    }
  }
}
