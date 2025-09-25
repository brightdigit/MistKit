import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Token Credentials")
/// Test suite for TokenCredentials and related functionality
struct TokenManagerTokenCredentialsTests {
  // MARK: - TokenCredentials Tests

  /// Tests TokenCredentials initialization and properties
  @Test("TokenCredentials initialization and properties")
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
  @Test("TokenCredentials convenience initializers")
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
    let keyData = Data("private-key".utf8)
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
  @Test("TokenCredentials computed properties")
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
  @Test("TokenCredentials Equatable conformance")
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
}
