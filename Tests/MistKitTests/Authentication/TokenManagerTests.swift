import Testing

@testable import MistKit
import Foundation

/// Test suite for TokenManager protocol and related types
struct TokenManagerTests {
  // MARK: - AuthenticationMethod Tests

  /// Tests AuthenticationMethod enum case creation and equality
  @Test
  func authenticationMethodCases() {
    // Test API token case
    let apiToken = AuthenticationMethod.apiToken("test-token-123")
    if case .apiToken(let token) = apiToken {
      #expect(token == "test-token-123")
    } else {
      Issue.record("Expected apiToken case")
    }

    // Test web auth token case
    let webAuth = AuthenticationMethod.webAuthToken(
      apiToken: "api-123",
      webToken: "web-456"
    )
    if case .webAuthToken(let api, let web) = webAuth {
      #expect(api == "api-123")
      #expect(web == "web-456")
    } else {
      Issue.record("Expected webAuthToken case")
    }

    // Test server-to-server case
    guard let keyData = "test-key".data(using: .utf8) else {
      Issue.record("Failed to create test key data")
      return
    }
    let serverAuth = AuthenticationMethod.serverToServer(
      keyID: "key-789",
      privateKey: keyData
    )
    if case .serverToServer(let keyID, let privateKey) = serverAuth {
      #expect(keyID == "key-789")
      #expect(privateKey == keyData)
    } else {
      Issue.record("Expected serverToServer case")
    }
  }

  /// Tests AuthenticationMethod computed properties
  @Test
  func authenticationMethodProperties() {
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
    #expect(apiToken.apiToken == "api-123")
    #expect(webAuth.apiToken == "api-456")
    #expect(serverAuth.apiToken == "")

    // Test webAuthToken property
    #expect(apiToken.webAuthToken == nil)
    #expect(webAuth.webAuthToken == "web-789")
    #expect(serverAuth.webAuthToken == nil)

    // Test serverKeyID property
    #expect(apiToken.serverKeyID == nil)
    #expect(webAuth.serverKeyID == nil)
    #expect(serverAuth.serverKeyID == "key-abc")

    // Test privateKeyData property
    #expect(apiToken.privateKeyData == nil)
    #expect(webAuth.privateKeyData == nil)
    #expect(serverAuth.privateKeyData != nil)

    // Test methodType property
    #expect(apiToken.methodType == "api-token")
    #expect(webAuth.methodType == "web-auth-token")
    #expect(serverAuth.methodType == "server-to-server")
  }

  /// Tests AuthenticationMethod Equatable conformance
  @Test
  func authenticationMethodEquality() {
    let apiToken1 = AuthenticationMethod.apiToken("same-token")
    let apiToken2 = AuthenticationMethod.apiToken("same-token")
    let apiToken3 = AuthenticationMethod.apiToken("different-token")

    #expect(apiToken1 == apiToken2)
    #expect(apiToken1 != apiToken3)

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

    #expect(webAuth1 == webAuth2)
    #expect(webAuth1 != webAuth3)

    guard let keyData = "test".data(using: .utf8) else {
      Issue.record("Failed to create test data")
      return
    }
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

    #expect(serverAuth1 == serverAuth2)
    #expect(serverAuth1 != serverAuth3)
  }

  // MARK: - TokenCredentials Tests

  /// Tests TokenCredentials initialization and properties
  @Test
  func tokenCredentialsInitialization() {
    let method = AuthenticationMethod.apiToken("test-token")
    let metadata = ["created": "2025-01-01", "environment": "test"]

    let credentials = TokenCredentials(method: method, metadata: metadata)

    #expect(credentials.method == method)
    #expect(credentials.metadata.count == 2)
    #expect(credentials.metadata["created"] == "2025-01-01")
    #expect(credentials.metadata["environment"] == "test")
  }

  /// Tests TokenCredentials convenience initializers
  @Test
  func tokenCredentialsConvenienceInitializers() {
    // Test apiToken convenience initializer
    let apiCredentials = TokenCredentials.apiToken("api-token-123")
    if case .apiToken(let token) = apiCredentials.method {
      #expect(token == "api-token-123")
    } else {
      Issue.record("Expected apiToken method")
    }

    // Test webAuthToken convenience initializer
    let webCredentials = TokenCredentials.webAuthToken(
      apiToken: "api-456",
      webToken: "web-789"
    )
    if case .webAuthToken(let api, let web) = webCredentials.method {
      #expect(api == "api-456")
      #expect(web == "web-789")
    } else {
      Issue.record("Expected webAuthToken method")
    }

    // Test serverToServer convenience initializer
    guard let keyData = "private-key".data(using: .utf8) else {
      Issue.record("Failed to create private key data")
      return
    }
    let serverCredentials = TokenCredentials.serverToServer(
      keyID: "server-key-id",
      privateKey: keyData
    )
    if case .serverToServer(let keyID, let privateKey) = serverCredentials.method {
      #expect(keyID == "server-key-id")
      #expect(privateKey == keyData)
    } else {
      Issue.record("Expected serverToServer method")
    }
  }

  /// Tests TokenCredentials computed properties
  @Test
  func tokenCredentialsProperties() {
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
    #expect(apiCredentials.supportsUserOperations == false)
    #expect(webCredentials.supportsUserOperations == true)
    #expect(serverCredentials.supportsUserOperations == true)

    // Test methodType
    #expect(apiCredentials.methodType == "api-token")
    #expect(webCredentials.methodType == "web-auth-token")
    #expect(serverCredentials.methodType == "server-to-server")
  }

  /// Tests TokenCredentials Equatable conformance
  @Test
  func tokenCredentialsEquality() {
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

    #expect(credentials1 == credentials2)
    #expect(credentials1 != credentials3)
    #expect(credentials1 != credentials4)  // Different metadata
  }

  // MARK: - TokenManagerError Tests

  /// Tests TokenManagerError cases and localized descriptions
  @Test
  func tokenManagerError() {
    let invalidError = TokenManagerError.invalidCredentials(reason: "Bad format")
    let authError = TokenManagerError.authenticationFailed(underlying: nil)
    let expiredError = TokenManagerError.tokenExpired
    let networkError = TokenManagerError.networkError(
      underlying: NSError(domain: "test", code: 123, userInfo: nil)
    )
    let internalError = TokenManagerError.internalError(reason: "System failure")

    // Test error descriptions
    #expect(invalidError.localizedDescription.contains("Invalid credentials"))
    #expect(invalidError.localizedDescription.contains("Bad format"))

    #expect(authError.localizedDescription.contains("Authentication failed"))

    #expect(expiredError.localizedDescription.contains("expired"))

    #expect(networkError.localizedDescription.contains("Network error"))

    #expect(internalError.localizedDescription.contains("Internal"))
    #expect(internalError.localizedDescription.contains("System failure"))
  }

  // MARK: - TokenManager Protocol Tests

  /// Tests TokenManager protocol conformance with mock implementation
  @Test
  func tokenManagerProtocolConformance() async throws {
    let mockManager = MockTokenManager()

    // Test protocol methods can be called
    let isValid = try await mockManager.validateCredentials()
    #expect(isValid == true)

    let credentials = try await mockManager.getCurrentCredentials()
    #expect(credentials != nil)

    // Test computed properties
    let hasCredentials = await mockManager.hasCredentials
    #expect(hasCredentials == true)
  }

  // MARK: - Sendable Compliance Tests

  /// Tests that all types are Sendable and can be used across async boundaries
  @Test
  func sendableCompliance() async {
    let method = AuthenticationMethod.apiToken("test")
    let credentials = TokenCredentials(method: method)
    let error = TokenManagerError.tokenExpired

    // Test concurrent access patterns
    async let task1 = Self.processCredentials(credentials)
    async let task2 = Self.processMethod(method)
    async let task3 = Self.processError(error)

    let results = await (task1, task2, task3)
    #expect(results.0 == "api-token")
    #expect(results.1 == "api-token")
    #expect(results.2.isEmpty == false)
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
final class MockTokenManager: TokenManager {
  var hasCredentials: Bool {
    get async { true }
  }

  func validateCredentials() async throws -> Bool {
    true
  }

  func getCurrentCredentials() async throws -> TokenCredentials? {
    TokenCredentials.apiToken("mock-token")
  }
}
