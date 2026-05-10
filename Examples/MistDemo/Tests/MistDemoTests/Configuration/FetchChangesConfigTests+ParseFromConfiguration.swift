//
//  FetchChangesConfigTests+ParseFromConfiguration.swift
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

extension FetchChangesConfigTests {
  private static func baseValues() -> [String: ConfigValue] {
    [
      "container.identifier": .init(stringLiteral: "iCloud.com.test.App"),
      "api.token": .init(stringLiteral: "test-api-token"),
      "environment": .init(stringLiteral: "development"),
      "database": .init(stringLiteral: "private"),
    ]
  }

  @Test("Parses defaults when no fetch-changes options are set")
  internal func parsesDefaults() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())

    let config = try await FetchChangesConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.syncToken == nil)
    #expect(config.zone == "_defaultZone")
    #expect(config.fetchAll == false)
    #expect(config.limit == nil)
    #expect(config.output == .table)
  }

  @Test("Parses sync token, zone, fetch-all, limit, and output format")
  internal func parsesAllOptions() async throws {
    var values = Self.baseValues()
    values["sync.token"] = .init(stringLiteral: "tok-7")
    values["zone"] = .init(stringLiteral: "myZone")
    values["fetch.all"] = .init(booleanLiteral: true)
    values["limit"] = .init(integerLiteral: 25)
    values["output.format"] = .init(stringLiteral: "json")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await FetchChangesConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.syncToken == "tok-7")
    #expect(config.zone == "myZone")
    #expect(config.fetchAll == true)
    #expect(config.limit == 25)
    #expect(config.output == .json)
  }

  @Test("Falls back to .table output for unknown formats")
  internal func unknownOutputFallsBackToTable() async throws {
    var values = Self.baseValues()
    values["output.format"] = .init(stringLiteral: "definitely-not-real")
    let configuration = MistDemoConfiguration.testing(values)

    let config = try await FetchChangesConfig(
      configuration: configuration,
      base: nil
    )

    #expect(config.output == .table)
  }

  @Test("Reuses an explicit base config")
  internal func reusesExplicitBase() async throws {
    let configuration = MistDemoConfiguration.testing(Self.baseValues())
    let baseConfig = try await MistDemoConfig()

    let config = try await FetchChangesConfig(
      configuration: configuration,
      base: baseConfig
    )

    #expect(config.base.containerIdentifier == baseConfig.containerIdentifier)
  }
}
