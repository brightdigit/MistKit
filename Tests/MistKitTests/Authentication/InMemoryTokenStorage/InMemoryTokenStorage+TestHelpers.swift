internal import Foundation
internal import Testing

@testable import MistKit

extension InMemoryTokenStorage {
  /// Test helper to store an authenticator and return a boolean result.
  internal func storeAuthenticator(_ authenticator: any Authenticator) async -> Bool {
    do {
      try await store(authenticator, identifier: nil)
      return true
    } catch {
      return false
    }
  }

  /// Test helper to get an authenticator by identifier.
  internal func getAuthenticator(identifier: String? = nil) async -> (any Authenticator)? {
    try? await retrieve(identifier: identifier)
  }

  /// Test helper to store and retrieve an authenticator.
  internal func storeAndRetrieve(_ authenticator: any Authenticator) async -> Bool {
    do {
      try await store(authenticator, identifier: nil)
      let retrieved = try await retrieve(identifier: nil)
      return retrieved != nil
    } catch {
      return false
    }
  }

  /// Test helper to remove a token by identifier.
  internal func removeToken(identifier: String) async -> Bool {
    do {
      try await remove(identifier: identifier)
      return true
    } catch {
      return false
    }
  }

  /// Test helper to get a token by identifier.
  internal func getToken(identifier: String) async -> (any Authenticator)? {
    try? await retrieve(identifier: identifier)
  }

  /// Test helper to store an API token authenticator under a key.
  internal func storeToken(key: String, token: String) async throws {
    let authenticator = try APITokenAuthenticator(token: token)
    try await store(authenticator, identifier: key)
  }
}
