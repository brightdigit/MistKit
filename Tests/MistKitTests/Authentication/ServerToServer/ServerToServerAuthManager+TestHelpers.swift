import Foundation
import Testing

@testable import MistKit

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension ServerToServerAuthManager {
  /// Test helper to validate credentials and return a boolean result
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func validateManager() async -> Bool {
    do {
      return try await validateCredentials()
    } catch {
      return false
    }
  }

  /// Test helper to get the current authenticator or nil on failure.
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func authenticatorFromManager() async -> (any Authenticator)? {
    do {
      return try await currentAuthenticator()
    } catch {
      return nil
    }
  }

  /// Test helper to check if credentials are available
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal func checkHasCredentials() async -> Bool {
    await hasCredentials
  }
}
