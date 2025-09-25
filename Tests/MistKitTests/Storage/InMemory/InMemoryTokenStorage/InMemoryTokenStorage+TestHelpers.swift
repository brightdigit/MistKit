import Foundation
import Testing

@testable import MistKit

extension InMemoryTokenStorage {
  /// Test helper to store credentials and return a boolean result
  internal func storeCredentials(_ credentials: TokenCredentials) async -> Bool {
    do {
      try await store(credentials, identifier: nil)
      return true
    } catch {
      return false
    }
  }

  /// Test helper to get credentials by identifier
  internal func getCredentials(identifier: String? = nil) async -> TokenCredentials? {
    try? await retrieve(identifier: identifier)
  }

  /// Test helper to store and retrieve credentials
  internal func storeAndRetrieve(_ credentials: TokenCredentials) async -> Bool {
    do {
      try await store(credentials, identifier: nil)
      let retrieved = try await retrieve(identifier: nil)
      return retrieved != nil
    } catch {
      return false
    }
  }

  /// Test helper to remove token by identifier
  internal func removeToken(identifier: String) async -> Bool {
    do {
      try await remove(identifier: identifier)
      return true
    } catch {
      return false
    }
  }

  /// Test helper to get token by identifier
  internal func getToken(identifier: String) async -> TokenCredentials? {
    try? await retrieve(identifier: identifier)
  }

  /// Test helper to store token with key and token string
  internal func storeToken(key: String, token: String) async throws {
    let credentials = TokenCredentials.apiToken(token)
    try await store(credentials, identifier: key)
  }
}
