//
//  AuthenticationCredentialsTests.swift
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
import MistKit
import Testing

@testable import MistDemoKit

@Suite("AuthenticationCredentials & DatabaseConfiguration")
internal enum AuthenticationCredentialsTests {
  @Suite("PrivateKeyMaterial")
  internal struct PrivateKeyMaterialTests {
    @Test("loadPEM raw returns content unchanged when no escapes present")
    internal func loadPEMRawPassthrough() throws {
      let pem = "-----BEGIN PRIVATE KEY-----\nABC\n-----END PRIVATE KEY-----"
      let material = PrivateKeyMaterial.raw(pem)

      #expect(try material.loadPEM() == pem)
    }

    @Test("loadPEM raw unescapes literal backslash-n into newline")
    internal func loadPEMRawUnescapesNewlines() throws {
      let escaped = "-----BEGIN PRIVATE KEY-----\\nABC\\n-----END PRIVATE KEY-----"
      let material = PrivateKeyMaterial.raw(escaped)

      let result = try material.loadPEM()

      #expect(result.contains("\n"))
      #expect(!result.contains("\\n"))
    }

    @Test(
      "loadPEM file reads UTF-8 contents",
      .disabled(if: TestPlatform.isWasm32, "WASI sandbox lacks reliable temp file IO")
    )
    internal func loadPEMFileSuccess() throws {
      let pem = "-----BEGIN PRIVATE KEY-----\ntest\n-----END PRIVATE KEY-----"
      let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("mistdemo-loadpem-\(UUID().uuidString).pem")
      try pem.write(to: url, atomically: true, encoding: .utf8)
      defer { try? FileManager.default.removeItem(at: url) }

      let material = PrivateKeyMaterial.file(path: url.path)
      #expect(try material.loadPEM() == pem)
    }

    @Test("loadPEM file throws missingRequired when file is unreadable")
    internal func loadPEMFileMissingThrows() throws {
      let material = PrivateKeyMaterial.file(path: "/non/existent/key-\(UUID().uuidString).pem")

      do {
        _ = try material.loadPEM()
        Issue.record("Expected ConfigurationError.missingRequired")
      } catch let error as ConfigurationError {
        if case .missingRequired(let key, _) = error {
          #expect(key == "private.key")
        } else {
          Issue.record("Wrong ConfigurationError case: \(error)")
        }
      }
    }
  }

  @Suite("makeTokenManager")
  internal struct MakeTokenManagerTests {
    @Test("webAuth produces a WebAuthTokenManager")
    internal func webAuthProducesManager() throws {
      let auth = AuthenticationCredentials.webAuth(
        apiToken: "api",
        webAuthToken: "web"
      )

      let manager = try auth.makeTokenManager()
      #expect(manager is WebAuthTokenManager)
    }

    @Test(
      "serverToServer with malformed PEM surfaces the auth manager error",
      .enabled(if: MistKitClientFactoryTests.isServerToServerSupported())
    )
    internal func serverToServerWithBadPEMThrows() throws {
      let auth = AuthenticationCredentials.serverToServer(
        keyID: "test-key-id",
        privateKey: .raw("not-a-real-pem")
      )

      #expect(throws: (any Error).self) {
        _ = try auth.makeTokenManager()
      }
    }
  }

  @Suite("DatabaseConfiguration.make validation")
  internal struct DatabaseConfigurationMakeTests {
    @Test("public + serverToServer is allowed")
    internal func publicWithServerToServerSucceeds() throws {
      let configuration = try DatabaseConfiguration.make(
        database: .public,
        authentication: .serverToServer(keyID: "k", privateKey: .raw("pem"))
      )
      #expect(configuration.database == .public)
    }

    @Test("public + webAuth is allowed")
    internal func publicWithWebAuthSucceeds() throws {
      let configuration = try DatabaseConfiguration.make(
        database: .public,
        authentication: .webAuth(apiToken: "a", webAuthToken: "w")
      )
      #expect(configuration.database == .public)
    }

    @Test("private + webAuth is allowed")
    internal func privateWithWebAuthSucceeds() throws {
      let configuration = try DatabaseConfiguration.make(
        database: .private,
        authentication: .webAuth(apiToken: "a", webAuthToken: "w")
      )
      #expect(configuration.database == .private)
    }

    @Test("shared + webAuth is allowed")
    internal func sharedWithWebAuthSucceeds() throws {
      let configuration = try DatabaseConfiguration.make(
        database: .shared,
        authentication: .webAuth(apiToken: "a", webAuthToken: "w")
      )
      #expect(configuration.database == .shared)
    }

    @Test("private + serverToServer is rejected")
    internal func privateWithServerToServerThrows() throws {
      #expect(throws: ConfigurationError.self) {
        _ = try DatabaseConfiguration.make(
          database: .private,
          authentication: .serverToServer(keyID: "k", privateKey: .raw("pem"))
        )
      }
    }

    @Test("shared + serverToServer is rejected")
    internal func sharedWithServerToServerThrows() throws {
      #expect(throws: ConfigurationError.self) {
        _ = try DatabaseConfiguration.make(
          database: .shared,
          authentication: .serverToServer(keyID: "k", privateKey: .raw("pem"))
        )
      }
    }
  }
}
