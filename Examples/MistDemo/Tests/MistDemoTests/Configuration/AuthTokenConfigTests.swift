//
//  AuthTokenConfigTests.swift
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

internal import Configuration
internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

@Suite("AuthTokenConfig Tests")
internal struct AuthTokenConfigTests {
  private static func key(_ path: String) -> AbsoluteConfigKey {
    AbsoluteConfigKey(path.split(separator: ".").map(String.init), context: [:])
  }

  private static func configuration(
    values: [String: ConfigValue]
  ) -> MistDemoConfiguration {
    var mapped: [AbsoluteConfigKey: ConfigValue] = [:]
    for (path, value) in values {
      mapped[key(path)] = value
    }
    return MistDemoConfiguration(testProvider: InMemoryProvider(values: mapped))
  }

  @Test("Memberwise init applies defaults for port, host, openBrowser, container")
  internal func memberwiseDefaults() {
    let config = AuthTokenConfig(apiToken: "tok")

    #expect(config.apiToken == "tok")
    #expect(config.containerIdentifier == MistDemoConstants.Defaults.containerIdentifier)
    #expect(config.environment == .development)
    #expect(config.port == 8_080)
    #expect(config.host == "127.0.0.1")
    // auth-token defaults to opening the browser.
    #expect(config.openBrowser == true)
  }

  @Test("Memberwise init accepts custom values for every field")
  internal func memberwiseCustom() {
    let config = AuthTokenConfig(
      apiToken: "tok",
      containerIdentifier: "iCloud.custom.id",
      environment: .production,
      port: 9_000,
      host: "0.0.0.0",
      openBrowser: false
    )

    #expect(config.apiToken == "tok")
    #expect(config.containerIdentifier == "iCloud.custom.id")
    #expect(config.environment == .production)
    #expect(config.port == 9_000)
    #expect(config.host == "0.0.0.0")
    #expect(config.openBrowser == false)
  }

  @Test("Configuration init throws missingRequired when api.token is absent")
  internal func missingApiTokenThrows() async {
    let configuration = Self.configuration(values: [:])

    await #expect(throws: ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }

  @Test("Configuration init throws missingRequired when api.token is empty")
  internal func emptyApiTokenThrows() async {
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "")
    ])

    await #expect(throws: ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }

  @Test("Configuration init applies all defaults when only api.token is set")
  internal func parsedDefaults() async throws {
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "tok-xyz")
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.apiToken == "tok-xyz")
    #expect(config.containerIdentifier == MistDemoConstants.Defaults.containerIdentifier)
    #expect(config.environment == .development)
    #expect(config.port == 8_080)
    #expect(config.host == "127.0.0.1")
    #expect(config.openBrowser == true)
  }

  @Test("Configuration init honors every override key")
  internal func parsedOverrides() async throws {
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "tok-xyz"),
      "container.identifier": .init(stringLiteral: "iCloud.custom.id"),
      "environment": .init(stringLiteral: "production"),
      "port": .init(integerLiteral: 9_090),
      "host": .init(stringLiteral: "192.168.1.10"),
      "no.browser": .init(booleanLiteral: true),
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.apiToken == "tok-xyz")
    #expect(config.containerIdentifier == "iCloud.custom.id")
    #expect(config.environment == .production)
    #expect(config.port == 9_090)
    #expect(config.host == "192.168.1.10")
    #expect(config.openBrowser == false)
  }

  @Test("--no-browser wins when both browser flags are set")
  internal func noBrowserWinsOverBrowser() async throws {
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "tok-xyz"),
      "browser": .init(booleanLiteral: true),
      "no.browser": .init(booleanLiteral: true),
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.openBrowser == false)
  }

  @Test("Configuration init throws on invalid environment")
  internal func invalidEnvironmentThrows() async {
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "tok-xyz"),
      "environment": .init(stringLiteral: "staging"),
    ])

    await #expect(throws: ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }
}
