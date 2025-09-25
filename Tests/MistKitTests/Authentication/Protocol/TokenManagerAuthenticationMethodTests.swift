import Foundation
import Testing

@testable import MistKit

@Suite("Token Manager - Authentication Method")
/// Test suite for AuthenticationMethod enum and related functionality
struct TokenManagerAuthenticationMethodTests {
  // MARK: - AuthenticationMethod Tests

  /// Tests AuthenticationMethod enum case creation and equality
  @Test("AuthenticationMethod enum case creation and equality")
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
    let keyData = Data("test-key".utf8)
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
  @Test("AuthenticationMethod computed properties")
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
  @Test("AuthenticationMethod Equatable conformance")
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

    let keyData = Data("test".utf8)
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
}
