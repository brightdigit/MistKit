import Foundation
import Testing

@testable import MistKit

@Suite("In-Memory Token Storage Replacement")
/// Test suite for InMemoryTokenStorage token replacement functionality
struct InMemoryTokenStorageReplacementTests {
  // MARK: - Test Data Setup

  private static let testAPIToken =
    "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
  private static let testWebAuthToken = "user123_web_auth_token_abcdef"

  // MARK: - Token Replacement Tests

  /// Tests replacing stored token with new token
  @Test("Replace stored token with new token")
  func replaceStoredTokenWithNewToken() async throws {
    let storage = InMemoryTokenStorage()
    let originalCredentials = TokenCredentials.apiToken(Self.testAPIToken)
    let newCredentials = TokenCredentials.webAuthToken(
      apiToken: Self.testAPIToken,
      webToken: Self.testWebAuthToken
    )

    try await storage.store(originalCredentials, identifier: nil)

    let retrievedBefore = try await storage.retrieve(identifier: nil)
    #expect(retrievedBefore != nil)

    try await storage.store(newCredentials, identifier: nil)

    let retrievedAfter = try await storage.retrieve(identifier: nil)
    #expect(retrievedAfter != nil)
    #expect(retrievedAfter == newCredentials)
    #expect(retrievedAfter != originalCredentials)
  }

  /// Tests replacing stored token with same token
  @Test("Replace stored token with same token")
  func replaceStoredTokenWithSameToken() async throws {
    let storage = InMemoryTokenStorage()
    let credentials = TokenCredentials.apiToken(Self.testAPIToken)

    try await storage.store(credentials, identifier: nil)

    let retrievedBefore = try await storage.retrieve(identifier: nil)
    #expect(retrievedBefore != nil)

    try await storage.store(credentials, identifier: nil)

    let retrievedAfter = try await storage.retrieve(identifier: nil)
    #expect(retrievedAfter != nil)
    #expect(retrievedAfter == credentials)
  }
}
