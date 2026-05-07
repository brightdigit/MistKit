import Crypto
import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorageTests {
  /// Test suite for InMemoryTokenStorage initialization and basic storage functionality
  @Suite("In-Memory Token Storage Initialization")
  internal struct InitializationTests {
    // MARK: - Test Data Setup

    private static let testAPIToken =
      TestConstants.apiToken
    private static let testWebAuthToken = TestConstants.webAuthToken

    // MARK: - Initialization Tests

    /// Tests InMemoryTokenStorage initialization
    @Test("InMemoryTokenStorage initialization")
    internal func initialization() {
      let storage = InMemoryTokenStorage()
      // Storage should be created successfully
      _ = storage
    }

    // MARK: - Token Storage Tests

    /// Tests storing API token
    @Test("Store API token")
    internal func storeAPIToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try APITokenAuthenticator(token: Self.testAPIToken)

      try await storage.store(authenticator, identifier: nil)

      let retrieved = try await storage.retrieve(identifier: nil)
      let api = try #require(retrieved as? APITokenAuthenticator)
      #expect(api.token == Self.testAPIToken)
    }

    /// Tests storing web auth token
    @Test("Store web auth token")
    internal func storeWebAuthToken() async throws {
      let storage = InMemoryTokenStorage()
      let authenticator = try WebAuthTokenAuthenticator(
        apiToken: Self.testAPIToken,
        webAuthToken: Self.testWebAuthToken
      )

      try await storage.store(authenticator, identifier: nil)

      let retrieved = try await storage.retrieve(identifier: nil)
      let web = try #require(retrieved as? WebAuthTokenAuthenticator)
      #expect(web.apiToken == Self.testAPIToken)
      #expect(web.webAuthToken == Self.testWebAuthToken)
    }

    /// Tests storing server-to-server credentials
    @Test(
      "Store server-to-server credentials",
      .enabled(if: Platform.isCryptoAvailable)
    )
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    internal func storeServerToServerCredentials() async throws {
      let storage = InMemoryTokenStorage()
      let keyID = "test-key-id-12345678"
      let privateKey = P256.Signing.PrivateKey()
      let authenticator = try ServerToServerAuthenticator(
        keyID: keyID,
        privateKey: privateKey
      )

      try await storage.store(authenticator, identifier: nil)

      let retrieved = try await storage.retrieve(identifier: nil)
      let s2s = try #require(retrieved as? ServerToServerAuthenticator)
      #expect(s2s.keyID == keyID)
      #expect(s2s.privateKey.rawRepresentation == privateKey.rawRepresentation)
    }
  }
}
