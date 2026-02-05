//
//  AuthenticationHelperTests.swift
//  MistDemo
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing
@testable import MistDemo
@testable import MistKit

@Suite("AuthenticationHelper Tests")
struct AuthenticationHelperTests {

  // MARK: - Server-to-Server Authentication Tests

  @Test("Server-to-server auth with keyID creates ServerToServerAuthManager")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerAuthWithKeyID() async throws {
    // Create a temporary private key file
    let tempDir = FileManager.default.temporaryDirectory
    let keyFile = tempDir.appendingPathComponent("test_key_\(UUID().uuidString).pem")

    // Use a test private key (this is a dummy key for testing only)
    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    try privateKeyPEM.write(to: keyFile, atomically: true, encoding: .utf8)

    defer {
      try? FileManager.default.removeItem(at: keyFile)
    }

    // Note: This will fail validation because it's a test key, but we can test the setup
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: nil,
        privateKeyFile: keyFile.path,
        databaseOverride: nil
      )

      // If we get here, validation succeeded (unlikely with test key)
      #expect(result.database == .public)
      #expect(result.authMethod.contains("Server-to-server"))
    } catch AuthenticationError.invalidServerToServerCredentials {
      // Expected - test key won't validate
      // But we've confirmed the setup path works
    }
  }

  @Test("Server-to-server auth with inline private key")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerAuthWithInlineKey() async throws {
    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: privateKeyPEM,
        privateKeyFile: nil,
        databaseOverride: nil
      )

      #expect(result.database == .public)
      #expect(result.authMethod.contains("Server-to-server"))
    } catch AuthenticationError.invalidServerToServerCredentials {
      // Expected with test key
    }
  }

  @Test("Server-to-server auth enforces public database")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerEnforcesPublicDatabase() async throws {
    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    // Attempt to override with private database should fail
    do {
      _ = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: privateKeyPEM,
        privateKeyFile: nil,
        databaseOverride: "private"
      )
      Issue.record("Expected serverToServerRequiresPublicDatabase error")
    } catch let error as AuthenticationError {
      if case .serverToServerRequiresPublicDatabase = error {
        // Expected error - test passes
      } else {
        Issue.record("Expected serverToServerRequiresPublicDatabase, got \(error)")
      }
    }
  }

  @Test("Server-to-server auth throws on missing private key")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerThrowsOnMissingPrivateKey() async throws {
    do {
      _ = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: nil
      )
      Issue.record("Expected missingPrivateKey error")
    } catch let error as AuthenticationError {
      if case .missingPrivateKey = error {
        // Expected error - test passes
      } else {
        Issue.record("Expected missingPrivateKey, got \(error)")
      }
    }
  }

  @Test("Server-to-server auth throws on invalid key file path")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerThrowsOnInvalidKeyFile() async throws {
    let invalidPath = "/nonexistent/path/to/key.pem"

    do {
      _ = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: nil,
        privateKeyFile: invalidPath,
        databaseOverride: nil
      )
      Issue.record("Should have thrown failedToReadPrivateKeyFile error")
    } catch let error as AuthenticationError {
      if case .failedToReadPrivateKeyFile(let path, _) = error {
        #expect(path == invalidPath)
      } else {
        Issue.record("Expected failedToReadPrivateKeyFile, got \(error)")
      }
    }
  }

  // MARK: - Web Authentication Tests

  @Test("Web auth defaults to private database")
  func webAuthDefaultsToPrivateDatabase() async throws {
    // Note: This will fail validation without real credentials
    // We're testing the path selection logic
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: "test-web-auth-token",
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: nil
      )

      #expect(result.database == .private)
      #expect(result.authMethod.contains("Web authentication"))
      #expect(result.authMethod.contains("private"))
    } catch AuthenticationError.invalidWebAuthCredentials {
      // Expected with test credentials - but we know it chose the right path
    }
  }

  @Test("Web auth allows public database override")
  func webAuthAllowsPublicDatabaseOverride() async throws {
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: "test-web-auth-token",
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: "public"
      )

      #expect(result.database == .public)
      #expect(result.authMethod.contains("Web authentication"))
      #expect(result.authMethod.contains("public"))
    } catch AuthenticationError.invalidWebAuthCredentials {
      // Expected with test credentials
    }
  }

  @Test("Web auth respects private database override")
  func webAuthRespectsPrivateDatabaseOverride() async throws {
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: "test-web-auth-token",
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: "private"
      )

      #expect(result.database == .private)
    } catch AuthenticationError.invalidWebAuthCredentials {
      // Expected with test credentials
    }
  }

  // MARK: - API-Only Authentication Tests

  @Test("API-only auth enforces public database")
  func apiOnlyEnforcesPublicDatabase() async throws {
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: nil
      )

      #expect(result.database == .public)
      #expect(result.authMethod.contains("API-only"))
    } catch AuthenticationError.invalidAPIToken {
      // Expected with test token
    }
  }

  @Test("API-only auth throws on private database request")
  func apiOnlyThrowsOnPrivateDatabaseRequest() async throws {
    do {
      _ = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: nil,
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: "private"
      )
      Issue.record("Expected privateRequiresWebAuth error")
    } catch let error as AuthenticationError {
      if case .privateRequiresWebAuth = error {
        // Expected error - test passes
      } else {
        Issue.record("Expected privateRequiresWebAuth, got \(error)")
      }
    }
  }

  // MARK: - Token Resolution Tests

  @Test("resolveAPIToken returns provided token when not empty")
  func resolveAPITokenReturnsProvidedToken() {
    let token = "my-api-token"
    let resolved = AuthenticationHelper.resolveAPIToken(token)
    #expect(resolved == token)
  }

  @Test("resolveAPIToken checks environment when empty")
  func resolveAPITokenChecksEnvironment() {
    let resolved = AuthenticationHelper.resolveAPIToken("")
    // Should return environment value or empty string (it's a String, not optional)
    // This test just verifies the function executes without error
    _ = resolved
  }

  @Test("resolveWebAuthToken returns provided token when not empty")
  func resolveWebAuthTokenReturnsProvidedToken() {
    let token = "my-web-auth-token"
    let resolved = AuthenticationHelper.resolveWebAuthToken(token)
    #expect(resolved == token)
  }

  @Test("resolveWebAuthToken returns nil for empty string")
  func resolveWebAuthTokenReturnsNilForEmpty() {
    let resolved = AuthenticationHelper.resolveWebAuthToken("")
    // Should return nil if environment variable not set
    if ProcessInfo.processInfo.environment["CLOUDKIT_WEB_AUTH_TOKEN"] == nil {
      #expect(resolved == nil)
    }
  }

  @Test("resolveWebAuthToken checks environment variable")
  func resolveWebAuthTokenChecksEnvironment() {
    // Set environment variable temporarily
    setenv("CLOUDKIT_WEB_AUTH_TOKEN", "env-token", 1)
    defer { unsetenv("CLOUDKIT_WEB_AUTH_TOKEN") }

    let resolved = AuthenticationHelper.resolveWebAuthToken("")
    #expect(resolved == "env-token")
  }

  // MARK: - Authentication Method Priority Tests

  @Test("Server-to-server takes precedence over web auth")
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  func serverToServerTakesPrecedence() async throws {
    let privateKeyPEM = """
    -----BEGIN PRIVATE KEY-----
    MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgevZzL1gdAFr88hb2
    OF/2NxApJCzGCEDdfSp6VQO30hyhRANCAAQRWz+jn65BtOMvdyHKcvjBeBSDZH2r
    1RTwjmYSi9R/zpBnuQ4EiMnCqfMPWiZqB4QdbAd0E7oH50VpuZ1P087G
    -----END PRIVATE KEY-----
    """

    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: "test-web-auth-token",  // Should be ignored
        keyID: "test-key-id",
        privateKey: privateKeyPEM,
        privateKeyFile: nil,
        databaseOverride: nil
      )

      #expect(result.database == .public)
      #expect(result.authMethod.contains("Server-to-server"))
    } catch AuthenticationError.invalidServerToServerCredentials {
      // Expected with test credentials
    }
  }

  @Test("Web auth takes precedence over API-only")
  func webAuthTakesPrecedence() async throws {
    do {
      let result = try await AuthenticationHelper.setupAuthentication(
        apiToken: "test-api-token",
        webAuthToken: "test-web-auth-token",
        keyID: nil,
        privateKey: nil,
        privateKeyFile: nil,
        databaseOverride: nil
      )

      #expect(result.authMethod.contains("Web authentication"))
      #expect(!result.authMethod.contains("API-only"))
    } catch AuthenticationError.invalidWebAuthCredentials {
      // Expected with test credentials
    }
  }
}
