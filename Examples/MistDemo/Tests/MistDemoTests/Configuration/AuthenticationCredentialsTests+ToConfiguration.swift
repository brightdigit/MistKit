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

internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension AuthenticationCredentialsTests {
  @Suite(
    "MistDemoConfig.toPrimaryCredentials",
    .disabled(
      if: TestPlatform.isWasm32,
      "MistDemoConfig construction relies on Foundation IO unavailable on WASI"
    )
  )
  internal struct ToPrimaryCredentialsTests {
    @Test("public with raw private key produces serverToServer with .raw material")
    internal func publicWithRawKey() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public(.prefers(.serverToServer)),
        keyID: "test-key-id",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let credentials = try config.toPrimaryCredentials()
      guard let s2s = credentials.serverToServer else {
        Issue.record("Expected serverToServer credentials")
        return
      }
      #expect(s2s.keyID == "test-key-id")
      if case .raw = s2s.privateKey {
        // expected
      } else {
        Issue.record("Expected .raw material, got \(s2s.privateKey)")
      }
    }

    @Test("public with private key file produces serverToServer with .file material")
    internal func publicWithFilePath() throws {
      let config = MistDemoConfig(
        containerIdentifier: "iCloud.com.test.App",
        apiToken: "test-api-token",
        environment: .development,
        database: .public(.prefers(.serverToServer)),
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

      let credentials = try config.toPrimaryCredentials()
      guard let s2s = credentials.serverToServer else {
        Issue.record("Expected serverToServer credentials")
        return
      }
      if case .file(let path) = s2s.privateKey {
        #expect(path == "/tmp/fake.pem")
      } else {
        Issue.record("Expected .file material, got \(s2s.privateKey)")
      }
    }

    @Test("public missing keyID throws missingRequired(\"key.id\")")
    internal func publicMissingKeyIDThrows() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        database: .public(.prefers(.serverToServer)),
        keyID: "",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      do {
        _ = try config.toPrimaryCredentials()
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
        database: .public(.prefers(.serverToServer)),
        keyID: "test-key-id"
      )

      do {
        _ = try config.toPrimaryCredentials()
        Issue.record("Expected ConfigurationError.missingRequired")
      } catch let error as ConfigurationError {
        if case .missingRequired(let key, _) = error {
          #expect(key == "private.key")
        } else {
          Issue.record("Wrong ConfigurationError case: \(error)")
        }
      }
    }

    @Test("private database resolves to apiAuth credentials with web-auth token")
    internal func privateHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .private,
        webAuthToken: "web"
      )

      let credentials = try config.toPrimaryCredentials()
      #expect(credentials.serverToServer == nil)
      #expect(credentials.apiAuth?.apiToken == "api")
      #expect(credentials.apiAuth?.webAuthToken == "web")
    }

    @Test("shared database resolves to apiAuth credentials with web-auth token")
    internal func sharedHappyPath() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .shared,
        webAuthToken: "web"
      )

      let credentials = try config.toPrimaryCredentials()
      #expect(credentials.serverToServer == nil)
      #expect(credentials.apiAuth?.apiToken == "api")
      #expect(credentials.apiAuth?.webAuthToken == "web")
    }
  }

  @Suite(
    "MistDemoConfig user-context credentials",
    .disabled(
      if: TestPlatform.isWasm32,
      "MistDemoConfig construction relies on Foundation IO unavailable on WASI"
    )
  )
  internal struct UserContextCredentialsTests {
    @Test("public with web-auth embeds apiAuth alongside serverToServer")
    internal func publicEmbedsAPIAuthWhenAvailable() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api",
        database: .public(.prefers(.serverToServer)),
        webAuthToken: "web",
        keyID: "k",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let credentials = try config.toPrimaryCredentials()
      #expect(credentials.serverToServer != nil)
      #expect(credentials.apiAuth?.apiToken == "api")
      #expect(credentials.apiAuth?.webAuthToken == "web")
      #expect(config.hasUserContextCredentials)
    }

    @Test("public without web-auth produces credentials without apiAuth")
    internal func publicOmitsAPIAuthWhenWebAuthMissing() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "",
        database: .public(.prefers(.serverToServer)),
        webAuthToken: nil,
        keyID: "k",
        privateKey: MistKitClientFactoryTests.validPrivateKey
      )

      let credentials = try config.toPrimaryCredentials()
      #expect(credentials.serverToServer != nil)
      #expect(credentials.apiAuth == nil)
      #expect(!config.hasUserContextCredentials)
    }
  }
}
