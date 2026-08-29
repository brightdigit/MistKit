//
//  TestPrivateConfigTests.swift
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
internal import Testing

@testable import MistDemoKit

@Suite("TestPrivateConfig Tests")
internal struct TestPrivateConfigTests {
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

  @Test("TestPrivateConfig retains sharee credentials")
  internal func retainsShareeCredentials() async throws {
    let base = try await MistDemoConfig()
    let config = TestPrivateConfig(
      base: base,
      shareeWebAuthToken: "sharee-token-value",
      shareeEmail: "sharee@example.com"
    )
    #expect(config.shareeWebAuthToken == "sharee-token-value")
    #expect(config.shareeEmail == "sharee@example.com")
  }

  @Test("Configuration init throws when sharee.web.auth.token is missing")
  internal func missingShareeTokenThrows() async throws {
    let base = try await MistDemoConfig(
      configuration: Self.configuration(values: [
        "api.token": .init(stringLiteral: "api-tok"),
        "web.auth.token": .init(stringLiteral: "sharer-tok"),
        "sharee.email": .init(stringLiteral: "sharee@example.com"),
      ]),
      base: nil
    )
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "api-tok"),
      "web.auth.token": .init(stringLiteral: "sharer-tok"),
      "sharee.email": .init(stringLiteral: "sharee@example.com"),
    ])

    await #expect(throws: ConfigurationError.self) {
      _ = try await TestPrivateConfig(configuration: configuration, base: base)
    }
  }

  @Test("Configuration init throws when sharee.email is missing")
  internal func missingShareeEmailThrows() async throws {
    let base = try await MistDemoConfig(
      configuration: Self.configuration(values: [
        "api.token": .init(stringLiteral: "api-tok"),
        "web.auth.token": .init(stringLiteral: "sharer-tok"),
        "sharee.web.auth.token": .init(stringLiteral: "sharee-tok"),
      ]),
      base: nil
    )
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "api-tok"),
      "web.auth.token": .init(stringLiteral: "sharer-tok"),
      "sharee.web.auth.token": .init(stringLiteral: "sharee-tok"),
    ])

    await #expect(throws: ConfigurationError.self) {
      _ = try await TestPrivateConfig(configuration: configuration, base: base)
    }
  }

  @Test("Configuration init parses required sharee credentials")
  internal func parsesShareeCredentials() async throws {
    let base = try await MistDemoConfig(
      configuration: Self.configuration(values: [
        "api.token": .init(stringLiteral: "api-tok"),
        "web.auth.token": .init(stringLiteral: "sharer-tok"),
      ]),
      base: nil
    )
    let configuration = Self.configuration(values: [
      "api.token": .init(stringLiteral: "api-tok"),
      "web.auth.token": .init(stringLiteral: "sharer-tok"),
      "sharee.web.auth.token": .init(stringLiteral: "sharee-tok"),
      "sharee.email": .init(stringLiteral: "sharee@example.com"),
    ])

    let config = try await TestPrivateConfig(
      configuration: configuration,
      base: base
    )
    #expect(config.shareeWebAuthToken == "sharee-tok")
    #expect(config.shareeEmail == "sharee@example.com")
  }
}
