//
//  DatabaseCredentialsTests.swift
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

@Suite("DatabaseCredentials")
internal enum DatabaseCredentialsTests {
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

  @Suite("database getter")
  internal struct DatabaseGetterTests {
    @Test("publicDatabase returns .public")
    internal func publicMapsToPublic() {
      let creds = DatabaseCredentials.publicDatabase(
        keyID: "k",
        privateKey: .raw("pem")
      )
      #expect(creds.database == .public)
    }

    @Test("privateDatabase returns .private")
    internal func privateMapsToPrivate() {
      let creds = DatabaseCredentials.privateDatabase(
        apiToken: "a",
        webAuthToken: "w"
      )
      #expect(creds.database == .private)
    }

    @Test("sharedDatabase returns .shared")
    internal func sharedMapsToShared() {
      let creds = DatabaseCredentials.sharedDatabase(
        apiToken: "a",
        webAuthToken: "w"
      )
      #expect(creds.database == .shared)
    }
  }

  @Suite("makeTokenManager")
  internal struct MakeTokenManagerTests {
    @Test("privateDatabase produces a WebAuthTokenManager")
    internal func privateProducesWebAuthManager() throws {
      let creds = DatabaseCredentials.privateDatabase(
        apiToken: "api",
        webAuthToken: "web"
      )

      let manager = try creds.makeTokenManager()
      #expect(manager is WebAuthTokenManager)
    }

    @Test("sharedDatabase produces a WebAuthTokenManager")
    internal func sharedProducesWebAuthManager() throws {
      let creds = DatabaseCredentials.sharedDatabase(
        apiToken: "api",
        webAuthToken: "web"
      )

      let manager = try creds.makeTokenManager()
      #expect(manager is WebAuthTokenManager)
    }

    @Test(
      "publicDatabase with malformed PEM surfaces the auth manager error",
      .enabled(if: MistKitClientFactoryTests.isServerToServerSupported())
    )
    internal func publicWithBadPEMThrows() throws {
      let creds = DatabaseCredentials.publicDatabase(
        keyID: "test-key-id",
        privateKey: .raw("not-a-real-pem")
      )

      #expect(throws: (any Error).self) {
        _ = try creds.makeTokenManager()
      }
    }
  }
}
