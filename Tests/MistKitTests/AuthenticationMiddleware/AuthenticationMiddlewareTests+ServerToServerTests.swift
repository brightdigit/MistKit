import Crypto
import Foundation
import HTTPTypes
import OpenAPIRuntime
import Testing

@testable import MistKit

enum AuthenticationMiddlewareTests {
}
extension AuthenticationMiddlewareTests {
  /// Server-to-server authentication tests for AuthenticationMiddleware
  @Suite("Server-to-Server Tests")
  public struct ServerToServerTests {
    // MARK: - Test Data Setup

    private static let testURL: URL = {
      guard let url = URL(string: "https://api.apple-cloudkit.com") else {
        fatalError("Invalid URL")
      }
      return url
    }()
    private static let testOperationID = "test-operation"

    // MARK: - Server-to-Server Authentication Tests

    /// Tests intercept with server-to-server authentication
    @Test("Intercept request with server-to-server authentication")
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func interceptWithServerToServerAuthentication() async throws {
      let keyID = "test-key-id-12345678"
      let tokenManager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: P256.Signing.PrivateKey()
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
        baseURL: Self.testURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)

      if let interceptedRequest = interceptedRequest {
        // Should have CloudKit-specific headers for server-to-server auth
        #expect(interceptedRequest.headerFields[.cloudKitRequestKeyID] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestISO8601Date] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestSignatureV1] != nil)
      }
    }

    /// Tests intercept with server-to-server authentication and existing headers
    @Test("Intercept request with server-to-server authentication and existing headers")
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func interceptWithServerToServerAuthenticationAndExistingHeaders() async throws {
      let keyID = "test-key-id-12345678"
      let tokenManager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: P256.Signing.PrivateKey()
      )
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      var originalRequest = HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )
      originalRequest.headerFields[.userAgent] = "TestAgent/1.0"
      originalRequest.headerFields[.contentType] = "application/json"

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
        // Should preserve existing headers
        #expect(interceptedRequest.headerFields[.userAgent] == "TestAgent/1.0")
        #expect(interceptedRequest.headerFields[.contentType] == "application/json")

        // Should add CloudKit-specific headers for server-to-server auth
        #expect(interceptedRequest.headerFields[.cloudKitRequestKeyID] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestISO8601Date] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestSignatureV1] != nil)
      }
    }

    /// Tests intercept with server-to-server authentication for POST request
    @Test("Intercept POST request with server-to-server authentication")
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    public func interceptPOSTWithServerToServerAuthentication() async throws {
      let keyID = "test-key-id-12345678"

      let tokenManager = try ServerToServerAuthManager(
        keyID: keyID,
        privateKeyCallback: P256.Signing.PrivateKey()
      )
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      let originalRequest = HTTPRequest(
        method: .post,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/modify"
      )

      var interceptedRequest: HTTPRequest?
      var interceptedBody: HTTPBody?

      let testBody = HTTPBody("test data")
      let next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?) = {
        request, body, _ in
        interceptedRequest = request
        interceptedBody = body
        return (HTTPResponse(status: .ok), nil)
      }

      _ = try await middleware.intercept(
        originalRequest,
        body: testBody,
        baseURL: Self.testURL,
        operationID: Self.testOperationID,
        next: next
      )

      #expect(interceptedRequest != nil)
      #expect(interceptedBody != nil)

      if let interceptedRequest = interceptedRequest {
        // Should have CloudKit-specific headers for server-to-server auth
        #expect(interceptedRequest.headerFields[.cloudKitRequestKeyID] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestISO8601Date] != nil)
        #expect(interceptedRequest.headerFields[.cloudKitRequestSignatureV1] != nil)
      }
    }
  }
}
