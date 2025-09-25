import Foundation
import Testing

@testable import MistKit

@Suite("API Token Manager Metadata")
enum APITokenManagerMetadataTests {}

extension APITokenManagerMetadataTests {
  /// Metadata and sendable compliance tests for APITokenManager
  @Suite("Metadata Tests")
  struct MetadataTests {
    // MARK: - Metadata Tests

    /// Tests credentialsWithMetadata method
    @Test("credentialsWithMetadata method")
    func credentialsWithMetadata() {
      let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
      let manager = APITokenManager(apiToken: validToken)

      let metadata = ["created": "2025-01-01", "environment": "test"]
      let credentials = manager.credentialsWithMetadata(metadata)

      if case .apiToken(let token) = credentials.method {
        #expect(token == validToken)
      } else {
        Issue.record("Expected .apiToken method")
      }

      #expect(credentials.metadata["created"] == "2025-01-01")
      #expect(credentials.metadata["environment"] == "test")
    }

    /// Tests credentialsWithMetadata with empty metadata
    @Test("credentialsWithMetadata with empty metadata")
    func credentialsWithEmptyMetadata() {
      let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
      let manager = APITokenManager(apiToken: validToken)

      let credentials = manager.credentialsWithMetadata([:])

      if case .apiToken(let token) = credentials.method {
        #expect(token == validToken)
      } else {
        Issue.record("Expected .apiToken method")
      }

      #expect(credentials.metadata.isEmpty)
    }

    // MARK: - Sendable Compliance Tests

    /// Tests that APITokenManager can be used across async boundaries
    @Test("APITokenManager sendable compliance")
    func sendableCompliance() async {
      let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
      let manager = APITokenManager(apiToken: validToken)

      // Test concurrent access patterns
      async let task1 = manager.validateManager()
      async let task2 = manager.getCredentialsFromManager()
      async let task3 = manager.checkHasCredentials()

      let results = await (task1, task2, task3)
      #expect(results.0 == true)
      #expect(results.1 != nil)
      #expect(results.2 == true)
    }
  }
}
