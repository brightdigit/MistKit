internal import Foundation
internal import HTTPTypes
internal import OpenAPIRuntime
internal import Testing

@testable import MistKit

extension AuthenticationMiddlewareTests {
  @Suite("Token Rotation")
  internal struct TokenRotation {
    private static let validAPIToken = TestConstants.apiToken
    private static let validWebAuthToken = TestConstants.webAuthToken
    private static let rotatedWebAuthToken =
      "rotatedwebauthtokenabcdef0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ"
      + "abcdefghijklmnopqrstuvwxyz0123456789AB=="
    private static let testOperationID = TestConstants.operationID

    private static func makeRequest() -> HTTPRequest {
      HTTPRequest(
        method: .get,
        scheme: "https",
        authority: "api.apple-cloudkit.com",
        path: "/database/1/iCloud.com.example.app/private/records/query"
      )
    }

    private static func responseWithRotatedToken(_ token: String) -> HTTPResponse {
      var response = HTTPResponse(status: .ok)
      response.headerFields[.cloudKitWebAuthToken] = token
      return response
    }

    @Test("Middleware forwards rotated token to token manager")
    internal func middlewareForwardsRotatedToken() async throws {
      let mockManager = MockTokenManagerWithRotation()
      let middleware = AuthenticationMiddleware(tokenManager: mockManager)

      _ = try await middleware.intercept(
        Self.makeRequest(),
        body: nil as HTTPBody?,
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: { _, _, _ in
          (Self.responseWithRotatedToken(Self.rotatedWebAuthToken), nil)
        }
      )

      let received = await mockManager.receivedRotatedTokens
      #expect(received == [Self.rotatedWebAuthToken])
    }

    @Test("Middleware skips rotation hook when header is absent")
    internal func middlewareSkipsRotationWithoutHeader() async throws {
      let mockManager = MockTokenManagerWithRotation()
      let middleware = AuthenticationMiddleware(tokenManager: mockManager)

      _ = try await middleware.intercept(
        Self.makeRequest(),
        body: nil as HTTPBody?,
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: { _, _, _ in
          (HTTPResponse(status: .ok), nil)
        }
      )

      let received = await mockManager.receivedRotatedTokens
      #expect(received.isEmpty)
    }

    @Test("Middleware returns response when rotation adoption fails")
    internal func middlewareReturnsResponseWhenRotationFails() async throws {
      let mockManager = MockTokenManagerWithRotationFailure()
      let middleware = AuthenticationMiddleware(tokenManager: mockManager)

      let (response, _) = try await RotatedWebAuthTokenFailureReporter.$assertionHandler.withValue(
        { _ in },
        operation: {
          try await middleware.intercept(
            Self.makeRequest(),
            body: nil as HTTPBody?,
            baseURL: CloudKitService.baseURL,
            operationID: Self.testOperationID,
            next: { _, _, _ in
              (Self.responseWithRotatedToken("short"), nil)
            }
          )
        }
      )

      #expect(response.status == .ok)
    }

    @Test("WebAuthTokenManager adopts rotated token from middleware")
    internal func webAuthTokenManagerAdoptsRotatedToken() async throws {
      let tokenManager = WebAuthTokenManager(
        apiToken: Self.validAPIToken,
        webAuthToken: Self.validWebAuthToken
      )
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      _ = try await middleware.intercept(
        Self.makeRequest(),
        body: nil as HTTPBody?,
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: { _, _, _ in
          (Self.responseWithRotatedToken(Self.rotatedWebAuthToken), nil)
        }
      )

      #expect(await tokenManager.webAuthToken == Self.rotatedWebAuthToken)
      let authenticator = try await tokenManager.currentAuthenticator()
      let web = try #require(authenticator as? WebAuthTokenAuthenticator)
      #expect(web.webAuthToken == Self.rotatedWebAuthToken)
    }

    @Test("AdaptiveTokenManager adopts rotated token from middleware")
    internal func adaptiveTokenManagerAdoptsRotatedToken() async throws {
      let tokenManager = AdaptiveTokenManager(apiToken: Self.validAPIToken)
      try await tokenManager.upgradeToWebAuthentication(webAuthToken: Self.validWebAuthToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      _ = try await middleware.intercept(
        Self.makeRequest(),
        body: nil as HTTPBody?,
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: { _, _, _ in
          (Self.responseWithRotatedToken(Self.rotatedWebAuthToken), nil)
        }
      )

      #expect(await tokenManager.webAuthToken == Self.rotatedWebAuthToken)
    }

    @Test("APITokenManager ignores rotated token via default implementation")
    internal func apiTokenManagerIgnoresRotation() async throws {
      let tokenManager = APITokenManager(apiToken: Self.validAPIToken)
      try await tokenManager.didReceiveRotatedWebAuthToken(Self.rotatedWebAuthToken)

      let authenticator = try await tokenManager.currentAuthenticator()
      #expect(authenticator is APITokenAuthenticator)
    }

    @Test("AdaptiveTokenManager ignores rotation before web auth upgrade")
    internal func adaptiveTokenManagerIgnoresRotationWithoutWebAuth() async throws {
      let tokenManager = AdaptiveTokenManager(apiToken: Self.validAPIToken)
      try await tokenManager.didReceiveRotatedWebAuthToken(Self.rotatedWebAuthToken)

      #expect(await tokenManager.webAuthToken == nil)
    }

    @Test("AdaptiveTokenManager ignores rotation from middleware before web auth upgrade")
    internal func adaptiveTokenManagerIgnoresMiddlewareRotationWithoutWebAuth() async throws {
      let tokenManager = AdaptiveTokenManager(apiToken: Self.validAPIToken)
      let middleware = AuthenticationMiddleware(tokenManager: tokenManager)

      _ = try await middleware.intercept(
        Self.makeRequest(),
        body: nil as HTTPBody?,
        baseURL: CloudKitService.baseURL,
        operationID: Self.testOperationID,
        next: { _, _, _ in
          (Self.responseWithRotatedToken(Self.rotatedWebAuthToken), nil)
        }
      )

      #expect(await tokenManager.webAuthToken == nil)
    }

    @Test("AdaptiveTokenManager persists rotated token to storage")
    internal func adaptiveTokenManagerPersistsRotatedTokenToStorage() async throws {
      let storage = InMemoryTokenStorage()
      let tokenManager = AdaptiveTokenManager(
        apiToken: Self.validAPIToken,
        storage: storage
      )
      try await tokenManager.upgradeToWebAuthentication(webAuthToken: Self.validWebAuthToken)
      try await tokenManager.didReceiveRotatedWebAuthToken(Self.rotatedWebAuthToken)

      let stored = try await storage.retrieve(identifier: Self.validAPIToken)
      let web = try #require(stored as? WebAuthTokenAuthenticator)
      #expect(web.webAuthToken == Self.rotatedWebAuthToken)
    }
  }
}
