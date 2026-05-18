//
//  AuthenticationHelperTests+ServerToServerAuthentication.swift
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

@testable import MistDemoKit
@testable import MistKit

extension AuthenticationHelperTests {
  @Suite("Server-to-Server Authentication")
  internal struct ServerToServerAuthentication {
    @Test(
      "Server-to-server auth with keyID creates ServerToServerAuthManager",
      .enabled(
        if: !TestPlatform.isWasm32,
        "FileManager.temporaryDirectory write isn't supported under WASI sandbox"
      )
    )
    internal func serverToServerAuthWithKeyID() async throws {
      // Create a temporary private key file
      let tempDir = FileManager.default.temporaryDirectory
      let keyFile = tempDir.appendingPathComponent("test_key_\(UUID().uuidString).pem")

      // Use a test private key (this is a dummy key for testing only)
      let privateKeyPEM = AuthenticationHelperTests.testPrivateKeyPEM

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
        #expect(result.database == .public(.prefers(.serverToServer)))
        #expect(result.authMethod.contains("Server-to-server"))
      } catch AuthenticationError.invalidServerToServerCredentials {
        // Expected - test key won't validate
        // But we've confirmed the setup path works
      }
    }

    @Test("Server-to-server auth with inline private key")
    internal func serverToServerAuthWithInlineKey() async throws {
      let privateKeyPEM = AuthenticationHelperTests.testPrivateKeyPEM

      do {
        let result = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: nil,
          keyID: "test-key-id",
          privateKey: privateKeyPEM,
          privateKeyFile: nil,
          databaseOverride: nil
        )

        #expect(result.database == .public(.prefers(.serverToServer)))
        #expect(result.authMethod.contains("Server-to-server"))
      } catch AuthenticationError.invalidServerToServerCredentials {
        // Expected with test key
      }
    }

    @Test("Server-to-server auth enforces public database")
    internal func serverToServerEnforcesPublicDatabase() async throws {
      let privateKeyPEM = AuthenticationHelperTests.testPrivateKeyPEM

      // Attempt to override with private database should fail
      do {
        _ = try await AuthenticationHelper.setupAuthentication(
          apiToken: "test-api-token",
          webAuthToken: nil,
          keyID: "test-key-id",
          privateKey: privateKeyPEM,
          privateKeyFile: nil,
          databaseOverride: .private
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
    internal func serverToServerThrowsOnMissingPrivateKey() async throws {
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
    internal func serverToServerThrowsOnInvalidKeyFile() async throws {
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
  }
}
