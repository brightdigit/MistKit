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

internal import Foundation
internal import Testing

@testable import MistDemoKit

@Suite("DemoErrorsConfig Tests")
internal struct DemoErrorsConfigTests {
  @Test("DemoErrorsConfig defaults scenario to all")
  internal func defaultsAll() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DemoErrorsConfig(base: baseConfig)

    #expect(config.scenario == .all)
  }

  @Test(
    "DemoErrorsConfig accepts each ErrorScenario value",
    arguments: ErrorScenario.allCases
  )
  internal func eachScenario(scenario: ErrorScenario) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DemoErrorsConfig(base: baseConfig, scenario: scenario)

    #expect(config.scenario == scenario)
  }

  @Test("ErrorScenario raw values match documented HTTP statuses")
  internal func rawValues() {
    #expect(ErrorScenario.all.rawValue == "all")
    #expect(ErrorScenario.unauthorized.rawValue == "401")
    #expect(ErrorScenario.notFound.rawValue == "404")
    #expect(ErrorScenario.conflict.rawValue == "409")
  }

  @Test("DemoErrorsError.invalidScenario lists every legal scenario in its message")
  internal func invalidScenarioMessage() {
    let error = DemoErrorsError.invalidScenario("bogus")
    let message = error.errorDescription ?? ""

    #expect(message.contains("bogus"))
    for scenario in ErrorScenario.allCases {
      #expect(message.contains(scenario.rawValue))
    }
  }
}
