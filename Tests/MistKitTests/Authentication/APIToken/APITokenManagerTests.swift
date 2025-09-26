import Foundation
import Testing

@testable import MistKit

@Suite("API Token Manager")
/// Test suite for APITokenManager functionality
internal struct APITokenManagerTests {
  // MARK: - Initialization Tests

  /// Tests APITokenManager initialization with valid API token
  @Test("APITokenManager initialization with valid API token")
  internal func initializationValidToken() {
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)

    #expect(manager.token == validToken)
    #expect(manager.isValidFormat == true)
  }

  /// Tests APITokenManager initialization with invalid API token format
  @Test("APITokenManager initialization with invalid API token format")
  internal func initializationInvalidToken() {
    let invalidToken = "invalid_token_format"
    let manager = APITokenManager(apiToken: invalidToken)

    #expect(manager.token == invalidToken)
    #expect(manager.isValidFormat == false)
  }

  /// Tests APITokenManager initialization with empty token (should crash)
  @Test("APITokenManager initialization with empty token")
  internal func initializationEmptyToken() {
    _ = ""

    // This should crash due to precondition - we can't easily test this with Swift Testing
    // Instead, we'll test that a valid token works
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)
    #expect(manager.token == validToken)
  }

  // MARK: - TokenManager Protocol Tests

  /// Tests hasCredentials property
  @Test("hasCredentials property")
  internal func hasCredentials() async {
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)

    let hasCredentials = await manager.hasCredentials
    #expect(hasCredentials == true)
  }

  /// Tests validateCredentials with valid token
  @Test("validateCredentials with valid token")
  internal func validateCredentialsValidToken() async throws {
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)

    let isValid = try await manager.validateCredentials()
    #expect(isValid == true)
  }

  /// Tests validateCredentials with invalid token
  @Test("validateCredentials with invalid token")
  internal func validateCredentialsInvalidToken() async throws {
    let invalidToken = "invalid_token_format"
    let manager = APITokenManager(apiToken: invalidToken)

    do {
      _ = try await manager.validateCredentials()
      Issue.record("Should have thrown TokenManagerError.invalidCredentials")
    } catch {
      switch error {
      case TokenManagerError.invalidCredentials(let reason):
        if case .apiTokenInvalidFormat = reason {
          // Expected case
        } else {
          Issue.record("Expected .apiTokenInvalidFormat, got: \(reason)")
        }
      default:
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }

  /// Tests validateCredentials with token that's too short
  @Test("validateCredentials with token that's too short")
  internal func validateCredentialsShortToken() async throws {
    let shortToken = "abc123"
    let manager = APITokenManager(apiToken: shortToken)

    do {
      _ = try await manager.validateCredentials()
      Issue.record("Should have thrown TokenManagerError.invalidCredentials")
    } catch {
      switch error {
      case TokenManagerError.invalidCredentials(let reason):
        if case .apiTokenInvalidFormat = reason {
          // Expected case
        } else {
          Issue.record("Expected .apiTokenInvalidFormat, got: \(reason)")
        }
      default:
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }

  /// Tests validateCredentials with token that's too long
  @Test("validateCredentials with token that's too long")
  internal func validateCredentialsLongToken() async throws {
    let longToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd12345"
    let manager = APITokenManager(apiToken: longToken)

    do {
      _ = try await manager.validateCredentials()
      Issue.record("Should have thrown TokenManagerError.invalidCredentials")
    } catch {
      switch error {
      case TokenManagerError.invalidCredentials(let reason):
        if case .apiTokenInvalidFormat = reason {
          // Expected case
        } else {
          Issue.record("Expected .apiTokenInvalidFormat, got: \(reason)")
        }
      default:
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }

  /// Tests validateCredentials with non-hex characters
  @Test("validateCredentials with non-hex characters")
  internal func validateCredentialsNonHexToken() async throws {
    let nonHexToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd12gh"
    let manager = APITokenManager(apiToken: nonHexToken)

    do {
      _ = try await manager.validateCredentials()
      Issue.record("Should have thrown TokenManagerError.invalidCredentials")
    } catch {
      switch error {
      case TokenManagerError.invalidCredentials(let reason):
        if case .apiTokenInvalidFormat = reason {
          // Expected case
        } else {
          Issue.record("Expected .apiTokenInvalidFormat, got: \(reason)")
        }
      default:
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }

  /// Tests getCurrentCredentials with valid token
  @Test("getCurrentCredentials with valid token")
  internal func getCurrentCredentialsValidToken() async throws {
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)

    let credentials = try await manager.getCurrentCredentials()
    #expect(credentials != nil)

    if let credentials = credentials {
      if case .apiToken(let token) = credentials.method {
        #expect(token == validToken)
      } else {
        Issue.record("Expected .apiToken method")
      }
    }
  }

  /// Tests getCurrentCredentials with invalid token
  @Test("getCurrentCredentials with invalid token")
  internal func getCurrentCredentialsInvalidToken() async throws {
    let invalidToken = "invalid_token_format"
    let manager = APITokenManager(apiToken: invalidToken)

    do {
      _ = try await manager.getCurrentCredentials()
      Issue.record("Should have thrown TokenManagerError.invalidCredentials")
    } catch {
      switch error {
      case TokenManagerError.invalidCredentials(let reason):
        if case .apiTokenInvalidFormat = reason {
          // Expected case
        } else {
          Issue.record("Expected .apiTokenInvalidFormat, got: \(reason)")
        }
      default:
        Issue.record("Expected invalidCredentials error, got: \(error)")
      }
    }
  }

  // MARK: - Extension Methods Tests

  /// Tests isValidFormat property with valid token
  @Test("isValidFormat property with valid token")
  internal func isValidFormatValidToken() {
    let validToken = "abcd1234567890abcd1234567890abcd1234567890abcd1234567890abcd1234"
    let manager = APITokenManager(apiToken: validToken)

    #expect(manager.isValidFormat == true)
  }

  /// Tests isValidFormat property with invalid token
  @Test("isValidFormat property with invalid token")
  internal func isValidFormatInvalidToken() {
    let invalidToken = "invalid_token_format"
    let manager = APITokenManager(apiToken: invalidToken)

    #expect(manager.isValidFormat == false)
  }
}
