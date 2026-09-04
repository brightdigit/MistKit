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

internal import ConfigKeyKit
internal import MistKitConfiguration
internal import Configuration
internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

@Suite("AuthTokenConfig Tests")
internal struct AuthTokenConfigTests {
  private static func configuration(
    values: [(key: any ConfigurationKey, value: String)]
  ) -> MistDemoConfiguration {
    MistDemoConfiguration.forTesting(values)
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
    #expect(config.resetAuth == false)
  }

  @Test("Memberwise init accepts custom values for every field")
  internal func memberwiseCustom() {
    let config = AuthTokenConfig(
      apiToken: "tok",
      containerIdentifier: "iCloud.custom.id",
      environment: .production,
      port: 9_000,
      host: "0.0.0.0",
      openBrowser: false,
      resetAuth: true
    )

    #expect(config.apiToken == "tok")
    #expect(config.containerIdentifier == "iCloud.custom.id")
    #expect(config.environment == .production)
    #expect(config.port == 9_000)
    #expect(config.host == "0.0.0.0")
    #expect(config.openBrowser == false)
    #expect(config.resetAuth == true)
  }

  @Test("Configuration init throws missingRequired when api.token is absent")
  internal func missingApiTokenThrows() async {
    let configuration = Self.configuration(values: [])

    await #expect(throws: MistDemoKit.ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }

  @Test("Configuration init throws missingRequired when api.token is empty")
  internal func emptyApiTokenThrows() async {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "")
    ])

    await #expect(throws: MistDemoKit.ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }

  @Test("Configuration init applies all defaults when only api.token is set")
  internal func parsedDefaults() async throws {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "tok-xyz")
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.apiToken == "tok-xyz")
    #expect(config.containerIdentifier == MistDemoConstants.Defaults.containerIdentifier)
    #expect(config.environment == .development)
    #expect(config.port == 8_080)
    #expect(config.host == "127.0.0.1")
    #expect(config.openBrowser == true)
    #expect(config.resetAuth == false)
  }

  @Test("Configuration init honors every override key")
  internal func parsedOverrides() async throws {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "tok-xyz"),
      (MistDemoKeys.cloudKit.containerID, "iCloud.custom.id"),
      (MistDemoKeys.cloudKit.environment, "production"),
      (MistDemoKeys.Server.port, String(9_090)),
      (MistDemoKeys.Server.host, "192.168.1.10"),
      (MistDemoKeys.Server.noBrowser, String(true)),
      (MistDemoKeys.Auth.resetAuth, String(true)),
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.apiToken == "tok-xyz")
    #expect(config.containerIdentifier == "iCloud.custom.id")
    #expect(config.environment == .production)
    #expect(config.port == 9_090)
    #expect(config.host == "192.168.1.10")
    #expect(config.openBrowser == false)
    #expect(config.resetAuth == true)
  }

  @Test("--no-browser wins when both browser flags are set")
  internal func noBrowserWinsOverBrowser() async throws {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "tok-xyz"),
      (MistDemoKeys.Server.browser, String(true)),
      (MistDemoKeys.Server.noBrowser, String(true)),
    ])

    let config = try await AuthTokenConfig(configuration: configuration)

    #expect(config.openBrowser == false)
  }

  @Test("Configuration init throws on invalid environment")
  internal func invalidEnvironmentThrows() async {
    let configuration = Self.configuration(values: [
      (MistDemoKeys.Auth.apiToken, "tok-xyz"),
      (MistDemoKeys.cloudKit.environment, "staging"),
    ])

    await #expect(throws: MistDemoKit.ConfigurationError.self) {
      _ = try await AuthTokenConfig(configuration: configuration)
    }
  }
}
