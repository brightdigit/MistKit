import Foundation
import Testing

@testable import MistKit

extension ServerToServerAuthManager {
  /// Test helper to validate credentials and return a boolean result
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func validateManager() async -> Bool {
    do {
      return try await validateCredentials()
    } catch {
      return false
    }
  }

  /// Test helper to get credentials and return them or nil
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func getCredentialsFromManager() async -> TokenCredentials? {
    do {
      return try await getCurrentCredentials()
    } catch {
      return nil
    }
  }

  /// Test helper to check if credentials are available
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func checkHasCredentials() async -> Bool {
    await hasCredentials
  }
}
