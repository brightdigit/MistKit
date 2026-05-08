//
//  AuthenticationCredentialsTests+ToConfiguration.swift
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

extension AuthenticationCredentialsTests {
  @Suite(
    "MistDemoConfig.toPrimaryConfiguration",
    .disabled(
      if: TestPlatform.isWasm32,
      "MistDemoConfig construction relies on Foundation IO unavailable on WASI"
    )
  )
  internal struct ToPrimaryConfigurationTests {
    @Test("public with raw private key produces .public + .serverToServer with .raw material")
    internal func publicWithRawKey() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public,
        keyID: "test-key-id",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let configuration = try config.toPrimaryConfiguration()
      #expect(configuration.database == .public)
      guard case .serverToServer(let keyID, let material) = configuration.authentication
      else {
        Issue.record("Expected .serverToServer, got \(configuration.authentication)")
        return
      }
      #expect(keyID == "test-key-id")
      if case .raw = material {
        // expected
      } else {
        Issue.record("Expected .raw material, got \(material)")
      }
    }

    @Test("public with private key file produces .serverToServer with .file material")
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

      let configuration = try config.toPrimaryConfiguration()
      guard case .serverToServer(_, let material) = configuration.authentication else {
        Issue.record("Expected .serverToServer, got \(configuration.authentication)")
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
        _ = try config.toPrimaryConfiguration()
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
        _ = try config.toPrimaryConfiguration()
        Issue.record("Expected ConfigurationError.missingRequired")
      } catch let error as ConfigurationError {
        if case .missingRequired(let key, _) = error {
          #expect(key == "private.key")
        } else {
          Issue.record("Wrong ConfigurationError case: \(error)")
        }
      }
    }

    @Test("private database resolves into .private + .webAuth")
    internal func privateHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .private,
        webAuthToken: "web"
      )

      let configuration = try config.toPrimaryConfiguration()
      #expect(configuration.database == .private)
      if case .webAuth(let api, let web) = configuration.authentication {
        #expect(api == "api")
        #expect(web == "web")
      } else {
        Issue.record("Expected .webAuth, got \(configuration.authentication)")
      }
    }

    @Test("shared database resolves into .shared + .webAuth")
    internal func sharedHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .shared,
        webAuthToken: "web"
      )

      let configuration = try config.toPrimaryConfiguration()
      #expect(configuration.database == .shared)
      if case .webAuth(let api, let web) = configuration.authentication {
        #expect(api == "api")
        #expect(web == "web")
      } else {
        Issue.record("Expected .webAuth, got \(configuration.authentication)")
      }
    }
  }

  @Suite(
    "MistDemoConfig.toUserContextConfiguration",
    .disabled(
      if: TestPlatform.isWasm32,
      "MistDemoConfig construction relies on Foundation IO unavailable on WASI"
    )
  )
  internal struct ToUserContextConfigurationTests {
    @Test("returns public+webAuth when web-auth tokens are populated")
    internal func returnsPublicWebAuthWhenAvailable() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .public,
        webAuthToken: "web",
        keyID: "k",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let userContext = config.toUserContextConfiguration()
      #expect(userContext != nil)
      #expect(userContext?.database == .public)
      if case .webAuth(let api, let web) = userContext?.authentication {
        #expect(api == "api")
        #expect(web == "web")
      } else {
        Issue.record("Expected .webAuth, got \(String(describing: userContext?.authentication))")
      }
    }

    @Test("returns nil when web-auth tokens are missing")
    internal func returnsNilWhenWebAuthMissing() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "",
        database: .public,
        webAuthToken: nil,
        keyID: "k",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      #expect(config.toUserContextConfiguration() == nil)
    }
  }
}
