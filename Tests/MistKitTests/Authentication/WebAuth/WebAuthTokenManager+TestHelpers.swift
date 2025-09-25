import Foundation
import Testing

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

  /// Test helper to get credentials and return them or nil
  internal func getCredentialsFromManager() async -> TokenCredentials? {
    do {
      return try await getCurrentCredentials()
    } catch {
      return nil
    }
  }

  /// Test helper to check if credentials are available
  internal func checkHasCredentials() async -> Bool {
    await hasCredentials
  }
}
