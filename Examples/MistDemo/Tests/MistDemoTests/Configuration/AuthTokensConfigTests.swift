//
//  AuthTokensConfigTests.swift
//  MistDemoTests
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

internal import ConfigKeyKit
internal import Configuration
internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

@Suite("AuthTokensConfig Tests")
internal struct AuthTokensConfigTests {
  private static func configuration(
    values: [(key: any ConfigurationKey, value: String)]
  ) -> MistDemoConfiguration {
    MistDemoConfiguration.forTesting(values)
  }

  @Test("Memberwise init applies defaults")
  internal func memberwiseDefaults() {
    let config = AuthTokensConfig(apiToken: "tok")

    #expect(config.apiToken == "tok")
    #expect(config.containerIdentifier == MistDemoConstants.Defaults.containerIdentifier)
    #expect(config.environment == .development)
    #expect(config.port == 8_080)
    #expect(config.host == "127.0.0.1")
    #expect(config.openBrowser == true)
    #expect(config.shareeEmail == nil)
  }

  @Test("Memberwise init accepts sharee email")
  internal func memberwiseWithShareeEmail() {
    let config = AuthTokensConfig(
      apiToken: "tok",
      shareeEmail: "sharee@example.com"
    )
    #expect(config.shareeEmail == "sharee@example.com")
  }

  @Test("Configuration init throws when api.token is absent")
  internal func missingApiTokenThrows() async {
    let configuration = Self.configuration(values: [])

    await #expect(throws: ConfigurationError.self) {
      _ = try await AuthTokensConfig(configuration: configuration)
    }
  }

  @Test("Configuration init parses sharee.email")
  internal func parsesShareeEmail() async throws {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "tok"),
      (MistDemoKeys.Auth.shareeEmail, "sharee@example.com"),
    ])

    let config = try await AuthTokensConfig(configuration: configuration)
    #expect(config.apiToken == "tok")
    #expect(config.shareeEmail == "sharee@example.com")
  }
}
