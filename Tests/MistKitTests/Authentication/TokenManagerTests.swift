public import XCTest
@testable import MistKit

/// Test suite for TokenManager protocol and related types
public final class TokenManagerTests: XCTestCase {

  // MARK: - AuthenticationMethod Tests

  /// Tests AuthenticationMethod enum case creation and equality
  public func testAuthenticationMethodCases() {
    // Test API token case
    let apiToken = AuthenticationMethod.apiToken("test-token-123")
    if case .apiToken(let token) = apiToken {
      XCTAssertEqual(token, "test-token-123")
    } else {
      XCTFail("Expected apiToken case")
    }

    // Test web auth token case
    let webAuth = AuthenticationMethod.webAuthToken(
      apiToken: "api-123",
      webToken: "web-456"
    )
    if case .webAuthToken(let api, let web) = webAuth {
      XCTAssertEqual(api, "api-123")
      XCTAssertEqual(web, "web-456")
    } else {
      XCTFail("Expected webAuthToken case")
    }

    // Test server-to-server case
    let keyData = "test-key".data(using: .utf8)!
    let serverAuth = AuthenticationMethod.serverToServer(
      keyID: "key-789",
      privateKey: keyData
    )
    if case .serverToServer(let keyID, let privateKey) = serverAuth {
      XCTAssertEqual(keyID, "key-789")
      XCTAssertEqual(privateKey, keyData)
    } else {
      XCTFail("Expected serverToServer case")
    }
  }

  /// Tests AuthenticationMethod computed properties
  public func testAuthenticationMethodProperties() {
    let apiToken = AuthenticationMethod.apiToken("api-123")
    let webAuth = AuthenticationMethod.webAuthToken(
      apiToken: "api-456",
      webToken: "web-789"
    )
    let serverAuth = AuthenticationMethod.serverToServer(
      keyID: "key-abc",
      privateKey: Data()
    )

    // Test apiToken property
    XCTAssertEqual(apiToken.apiToken, "api-123")
    XCTAssertEqual(webAuth.apiToken, "api-456")
    XCTAssertEqual(serverAuth.apiToken, "")

    // Test webAuthToken property
    XCTAssertNil(apiToken.webAuthToken)
    XCTAssertEqual(webAuth.webAuthToken, "web-789")
    XCTAssertNil(serverAuth.webAuthToken)

    // Test serverKeyID property
    XCTAssertNil(apiToken.serverKeyID)
    XCTAssertNil(webAuth.serverKeyID)
    XCTAssertEqual(serverAuth.serverKeyID, "key-abc")

    // Test privateKeyData property
    XCTAssertNil(apiToken.privateKeyData)
    XCTAssertNil(webAuth.privateKeyData)
    XCTAssertNotNil(serverAuth.privateKeyData)

    // Test methodType property
    XCTAssertEqual(apiToken.methodType, "api-token")
    XCTAssertEqual(webAuth.methodType, "web-auth-token")
    XCTAssertEqual(serverAuth.methodType, "server-to-server")
  }

  /// Tests AuthenticationMethod Equatable conformance
  public func testAuthenticationMethodEquality() {
    let apiToken1 = AuthenticationMethod.apiToken("same-token")
    let apiToken2 = AuthenticationMethod.apiToken("same-token")
    let apiToken3 = AuthenticationMethod.apiToken("different-token")

    XCTAssertEqual(apiToken1, apiToken2)
    XCTAssertNotEqual(apiToken1, apiToken3)

    let webAuth1 = AuthenticationMethod.webAuthToken(
      apiToken: "api",
      webToken: "web"
    )
    let webAuth2 = AuthenticationMethod.webAuthToken(
      apiToken: "api",
      webToken: "web"
    )
    let webAuth3 = AuthenticationMethod.webAuthToken(
      apiToken: "api",
      webToken: "different"
    )

    XCTAssertEqual(webAuth1, webAuth2)
    XCTAssertNotEqual(webAuth1, webAuth3)

    let keyData = "test".data(using: .utf8)!
    let serverAuth1 = AuthenticationMethod.serverToServer(
      keyID: "key1",
      privateKey: keyData
    )
    let serverAuth2 = AuthenticationMethod.serverToServer(
      keyID: "key1",
      privateKey: keyData
    )
    let serverAuth3 = AuthenticationMethod.serverToServer(
      keyID: "key2",
      privateKey: keyData
    )

    XCTAssertEqual(serverAuth1, serverAuth2)
    XCTAssertNotEqual(serverAuth1, serverAuth3)
  }

  // MARK: - TokenCredentials Tests

  /// Tests TokenCredentials initialization and properties
  public func testTokenCredentialsInitialization() {
    let method = AuthenticationMethod.apiToken("test-token")
    let metadata = ["created": "2025-01-01", "environment": "test"]

    let credentials = TokenCredentials(method: method, metadata: metadata)

    XCTAssertEqual(credentials.method, method)
    XCTAssertEqual(credentials.metadata.count, 2)
    XCTAssertEqual(credentials.metadata["created"], "2025-01-01")
    XCTAssertEqual(credentials.metadata["environment"], "test")
  }

  /// Tests TokenCredentials convenience initializers
  public func testTokenCredentialsConvenienceInitializers() {
    // Test apiToken convenience initializer
    let apiCredentials = TokenCredentials.apiToken("api-token-123")
    if case .apiToken(let token) = apiCredentials.method {
      XCTAssertEqual(token, "api-token-123")
    } else {
      XCTFail("Expected apiToken method")
    }

    // Test webAuthToken convenience initializer
    let webCredentials = TokenCredentials.webAuthToken(
      apiToken: "api-456",
      webToken: "web-789"
    )
    if case .webAuthToken(let api, let web) = webCredentials.method {
      XCTAssertEqual(api, "api-456")
      XCTAssertEqual(web, "web-789")
    } else {
      XCTFail("Expected webAuthToken method")
    }

    // Test serverToServer convenience initializer
    let keyData = "private-key".data(using: .utf8)!
    let serverCredentials = TokenCredentials.serverToServer(
      keyID: "server-key-id",
      privateKey: keyData
    )
    if case .serverToServer(let keyID, let privateKey) = serverCredentials.method {
      XCTAssertEqual(keyID, "server-key-id")
      XCTAssertEqual(privateKey, keyData)
    } else {
      XCTFail("Expected serverToServer method")
    }
  }

  /// Tests TokenCredentials computed properties
  public func testTokenCredentialsProperties() {
    let apiCredentials = TokenCredentials.apiToken("test")
    let webCredentials = TokenCredentials.webAuthToken(
      apiToken: "api",
      webToken: "web"
    )
    let serverCredentials = TokenCredentials.serverToServer(
      keyID: "key",
      privateKey: Data()
    )

    // Test supportsUserOperations
    XCTAssertFalse(apiCredentials.supportsUserOperations)
    XCTAssertTrue(webCredentials.supportsUserOperations)
    XCTAssertTrue(serverCredentials.supportsUserOperations)

    // Test methodType
    XCTAssertEqual(apiCredentials.methodType, "api-token")
    XCTAssertEqual(webCredentials.methodType, "web-auth-token")
    XCTAssertEqual(serverCredentials.methodType, "server-to-server")
  }

  /// Tests TokenCredentials Equatable conformance
  public func testTokenCredentialsEquality() {
    let method1 = AuthenticationMethod.apiToken("same-token")
    let method2 = AuthenticationMethod.apiToken("same-token")
    let method3 = AuthenticationMethod.apiToken("different-token")

    let credentials1 = TokenCredentials(method: method1)
    let credentials2 = TokenCredentials(method: method2)
    let credentials3 = TokenCredentials(method: method3)
    let credentials4 = TokenCredentials(
      method: method1,
      metadata: ["test": "value"]
    )

    XCTAssertEqual(credentials1, credentials2)
    XCTAssertNotEqual(credentials1, credentials3)
    XCTAssertNotEqual(credentials1, credentials4) // Different metadata
  }

  // MARK: - TokenManagerError Tests

  /// Tests TokenManagerError cases and localized descriptions
  public func testTokenManagerError() {
    let invalidError = TokenManagerError.invalidCredentials(reason: "Bad format")
    let authError = TokenManagerError.authenticationFailed(underlying: nil)
    let refreshError = TokenManagerError.refreshNotSupported
    let expiredError = TokenManagerError.tokenExpired
    let networkError = TokenManagerError.networkError(
      underlying: NSError(domain: "test", code: 123, userInfo: nil)
    )
    let internalError = TokenManagerError.internalError(reason: "System failure")

    // Test error descriptions
    XCTAssertTrue(invalidError.localizedDescription.contains("Invalid credentials"))
    XCTAssertTrue(invalidError.localizedDescription.contains("Bad format"))

    XCTAssertTrue(authError.localizedDescription.contains("Authentication failed"))

    XCTAssertTrue(refreshError.localizedDescription.contains("not supported"))

    XCTAssertTrue(expiredError.localizedDescription.contains("expired"))

    XCTAssertTrue(networkError.localizedDescription.contains("Network error"))

    XCTAssertTrue(internalError.localizedDescription.contains("Internal"))
    XCTAssertTrue(internalError.localizedDescription.contains("System failure"))
  }

  // MARK: - TokenManager Protocol Tests

  /// Tests TokenManager protocol conformance with mock implementation
  public func testTokenManagerProtocolConformance() async throws {
    let mockManager = MockTokenManager()

    // Test protocol methods can be called
    let isValid = try await mockManager.validateCredentials()
    XCTAssertTrue(isValid)

    let credentials = try await mockManager.getCurrentCredentials()
    XCTAssertNotNil(credentials)

    let refreshedCredentials = try await mockManager.refreshCredentials()
    XCTAssertNotNil(refreshedCredentials)

    // Test computed properties
    XCTAssertTrue(mockManager.supportsRefresh)
    let hasCredentials = await mockManager.hasCredentials
    XCTAssertTrue(hasCredentials)
  }

  // MARK: - Sendable Compliance Tests

  /// Tests that all types are Sendable and can be used across async boundaries
  public func testSendableCompliance() async {
    let method = AuthenticationMethod.apiToken("test")
    let credentials = TokenCredentials(method: method)
    let error = TokenManagerError.tokenExpired

    // Test concurrent access patterns
    async let task1 = Self.processCredentials(credentials)
    async let task2 = Self.processMethod(method)
    async let task3 = Self.processError(error)

    let results = await (task1, task2, task3)
    XCTAssertEqual(results.0, "api-token")
    XCTAssertEqual(results.1, "api-token")
    XCTAssertFalse(results.2.isEmpty)
  }

  // MARK: - Helper Methods

  private static func processCredentials(_ credentials: TokenCredentials) async -> String {
    credentials.methodType
  }

  private static func processMethod(_ method: AuthenticationMethod) async -> String {
    method.methodType
  }

  private static func processError(_ error: TokenManagerError) async -> String {
    error.localizedDescription
  }
}

// MARK: - Mock TokenManager Implementation

/// Mock implementation of TokenManager for testing protocol conformance
internal final class MockTokenManager: TokenManager {
  let supportsRefresh = true

  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    return true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    return TokenCredentials.apiToken("mock-token")
  }

  func refreshCredentials() async throws -> TokenCredentials? {
    return TokenCredentials.apiToken("refreshed-mock-token")
  }
}