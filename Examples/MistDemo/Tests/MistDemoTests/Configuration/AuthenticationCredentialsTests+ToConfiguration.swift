//
//  DatabaseCredentialsTests+ToDatabaseCredentials.swift
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

extension DatabaseCredentialsTests {
  @Suite(
    "MistDemoConfig.toDatabaseCredentials",
    .disabled(
      if: TestPlatform.isWasm32,
      "MistDemoConfig construction relies on Foundation IO unavailable on WASI"
    )
  )
  internal struct ToDatabaseCredentialsTests {
    @Test("public with raw private key produces .publicDatabase with .raw material")
    internal func publicWithRawKey() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public,
        keyID: "test-key-id",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let creds = try config.toDatabaseCredentials()
      guard case .publicDatabase(let keyID, let material) = creds else {
        Issue.record("Expected .publicDatabase, got \(creds)")
        return
      }
      #expect(keyID == "test-key-id")
      if case .raw = material {
        // expected
      } else {
        Issue.record("Expected .raw material, got \(material)")
      }
    }

    @Test("public with private key file produces .publicDatabase with .file material")
    internal func publicWithFilePath() throws {
      let config = MistDemoConfig(
        containerIdentifier: "iCloud.com.test.App",
        apiToken: "test-api-token",
        environment: .development,
        database: .public,
        webAuthToken: nil,
        keyID: "test-key-id",
        privateKey: nil,
        privateKeyFile: "/tmp/fake.pem",
        host: "127.0.0.1",
        port: 8_080,
        authTimeout: 300,
        skipAuth: false,
        testAllAuth: false,
        testApiOnly: false,
        testAdaptive: false,
        testServerToServer: false,
        badCredentials: false
      )

      let creds = try config.toDatabaseCredentials()
      guard case .publicDatabase(_, let material) = creds else {
        Issue.record("Expected .publicDatabase, got \(creds)")
        return
      }
      if case .file(let path) = material {
        #expect(path == "/tmp/fake.pem")
      } else {
        Issue.record("Expected .file material, got \(material)")
      }
    }

    @Test("public missing keyID throws missingRequired(\"key.id\")")
    internal func publicMissingKeyIDThrows() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public,
        keyID: "",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      do {
        _ = try config.toDatabaseCredentials()
        Issue.record("Expected ConfigurationError.missingRequired")
      } catch let error as ConfigurationError {
        if case .missingRequired(let key, _) = error {
          #expect(key == "key.id")
        } else {
          Issue.record("Wrong ConfigurationError case: \(error)")
        }
      }
    }

    @Test("public missing private key material throws missingRequired(\"private.key\")")
    internal func publicMissingPrivateKeyThrows() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public,
        keyID: "test-key-id"
      )

      do {
        _ = try config.toDatabaseCredentials()
        Issue.record("Expected ConfigurationError.missingRequired")
      } catch let error as ConfigurationError {
        if case .missingRequired(let key, _) = error {
          #expect(key == "private.key")
        } else {
          Issue.record("Wrong ConfigurationError case: \(error)")
        }
      }
    }

    @Test("private database resolves into .privateDatabase")
    internal func privateHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .private,
        webAuthToken: "web"
      )

      let creds = try config.toDatabaseCredentials()
      if case .privateDatabase(let api, let web) = creds {
        #expect(api == "api")
        #expect(web == "web")
      } else {
        Issue.record("Expected .privateDatabase, got \(creds)")
      }
    }

    @Test("shared database resolves into .sharedDatabase")
    internal func sharedHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .shared,
        webAuthToken: "web"
      )

      let creds = try config.toDatabaseCredentials()
      if case .sharedDatabase(let api, let web) = creds {
        #expect(api == "api")
        #expect(web == "web")
      } else {
        Issue.record("Expected .sharedDatabase, got \(creds)")
      }
    }
  }
}
