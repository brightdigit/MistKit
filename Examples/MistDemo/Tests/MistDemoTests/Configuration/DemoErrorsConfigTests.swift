//
//  DemoErrorsConfigTests.swift
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

import Configuration
import Foundation
import Testing

@testable import MistDemoKit

@Suite("DemoErrorsConfig")
internal struct DemoErrorsConfigTests {
  private static func baseValues(
    scenario: String? = nil
  ) -> [String: ConfigValue] {
    var values: [String: ConfigValue] = [
      "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
      "api.token": .init(stringLiteral: "test-api-token"),
      "environment": .init(stringLiteral: "development"),
      "database": .init(stringLiteral: "private"),
    ]
    if let scenario {
      values["scenario"] = .init(stringLiteral: scenario)
    }
    return values
  }

  @Test("DemoErrorsConfig defaults to .all when scenario is unset")
  internal func defaultsToAll() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())

    let config = try await DemoErrorsConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.scenario == .all)
  }

  @Test("DemoErrorsConfig parses scenario raw values", arguments: ErrorScenario.allCases)
  internal func parsesScenarioRawValues(
    expected: ErrorScenario
  ) async throws {
    let configuration = MistDemoConfiguration.testing(
      Self.baseValues(scenario: expected.rawValue)
    )

    let config = try await DemoErrorsConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.scenario == expected)
  }

  @Test("DemoErrorsConfig throws invalidScenario on unknown raw values")
  internal func throwsOnUnknownScenario() async throws {
    let configuration = MistDemoConfiguration.testing(
      Self.baseValues(scenario: "418")
    )

    await #expect(throws: DemoErrorsError.self) {
      _ = try await DemoErrorsConfig(
        configuration: configuration,
        base: nil
      )
    }
  }

  @Test("DemoErrorsConfig accepts memberwise base + scenario")
  internal func memberwiseInit() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DemoErrorsConfig(base: baseConfig, scenario: .conflict)

    #expect(config.scenario == .conflict)
  }

  @Test("DemoErrorsConfig reuses an explicit base config")
  internal func reusesExplicitBase() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())
    let baseConfig = try await MistDemoConfig()

    let config = try await DemoErrorsConfig(
      configuration: configuration,
      base: baseConfig
    )

    #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
  }

  @Test("ErrorScenario covers all four cases")
  internal func errorScenarioCases() {
    #expect(ErrorScenario.allCases.count == 4)
    #expect(Set(ErrorScenario.allCases.map(\.rawValue)) == [
      "all", "401", "404", "409",
    ])
  }
}
