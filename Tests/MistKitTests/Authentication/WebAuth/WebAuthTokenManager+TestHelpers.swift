internal import Foundation
internal import Testing

@testable import MistKit

extension WebAuthTokenManager {
  /// Test helper to validate credentials and return a boolean result
  internal func validateManager() async -> Bool {
    do {
      return try await validateCredentials()
    } catch {
      return false
    }
  }

  /// Test helper to get the current authenticator or nil on failure.
  internal func authenticatorFromManager() async -> (any Authenticator)? {
    do {
      return try await currentAuthenticator()
    } catch {
      return nil
    }
  }

  /// Test helper to check if credentials are available
  internal func checkHasCredentials() async -> Bool {
    await hasCredentials
  }
}
