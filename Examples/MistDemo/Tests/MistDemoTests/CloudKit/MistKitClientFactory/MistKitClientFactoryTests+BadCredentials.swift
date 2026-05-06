//
//  MistKitClientFactoryTests+BadCredentials.swift
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

extension MistKitClientFactoryTests {
  @Suite("Bad Credentials")
  internal struct BadCredentials {
    @Test("badCredentials short-circuits to web-auth on private database")
    internal func badCredentialsOnPrivateDatabase() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "real-config-token",
        database: .private,
        webAuthToken: "real-config-web-auth-token",
        badCredentials: true
      )

      // Must not throw, even though the configured tokens are unrelated to a real
      // CloudKit account — the factory swaps in placeholder tokens for the demo.
      _ = try MistKitClientFactory.create(for: config)
    }

    @Test("badCredentials short-circuits to web-auth on shared database")
    internal func badCredentialsOnSharedDatabase() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "real-config-token",
        database: .shared,
        webAuthToken: "real-config-web-auth-token",
        badCredentials: true
      )

      _ = try MistKitClientFactory.create(for: config)
    }

    @Test("badCredentials throws on public database")
    internal func badCredentialsOnPublicDatabaseThrows() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "real-config-token",
        database: .public,
        keyID: "real-key-id",
        privateKey: MistKitClientFactoryTests.validPrivateKey,
        badCredentials: true
      )

      do {
        _ = try MistKitClientFactory.create(for: config)
        Issue.record(
          "Should have thrown ConfigurationError.badCredentialsNotSupportedOnPublicDatabase")
      } catch ConfigurationError.badCredentialsNotSupportedOnPublicDatabase {
        // expected
      } catch {
        Issue.record("Wrong error: \(error)")
      }
    }

    @Test("badCredentials = false leaves normal auth selection intact")
    internal func badCredentialsFalseRegression() async throws {
      let config = try await MistKitClientFactoryTests.makeConfig(
        apiToken: "api-token",
        database: .private,
        webAuthToken: "web-auth-token",
        badCredentials: false
      )

      _ = try MistKitClientFactory.create(for: config)
    }

    @Test("makeBadCredentialsTokenManager produces format-valid tokens")
    internal func badCredentialsTokenManagerFormatPassesLocalValidation() async throws {
      // The 401 demo only works if the tokens pass WebAuthTokenManager's local
      // format check (64-char hex API token + ≥10-char web-auth token) — otherwise
      // the request never reaches Apple and httpStatusCode comes back nil.
      let manager = MistKitClientFactory.makeBadCredentialsTokenManager()
      let validated = try await manager.validateCredentials()
      #expect(validated)
    }
  }
}
