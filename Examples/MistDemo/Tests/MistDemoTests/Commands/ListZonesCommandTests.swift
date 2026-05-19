//
//  ListZonesCommandTests.swift
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
internal import MistKit
internal import Testing

@testable import MistDemoKit

@Suite("ListZonesCommand Tests")
internal struct ListZonesCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(ListZonesCommand.commandName == "list-zones")
    #expect(ListZonesCommand.abstract == "List all zones in the database")
    #expect(ListZonesCommand.helpText.contains("LIST-ZONES"))
  }

  @Test("Config defaults")
  internal func configDefaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ListZonesConfig(base: baseConfig)
    #expect(config.includeDefault == false)
    #expect(config.output == .table)
  }

  @Test("Config accepts custom values")
  internal func configCustom() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ListZonesConfig(
      base: baseConfig,
      includeDefault: true,
      output: .json
    )
    #expect(config.includeDefault)
    #expect(config.output == .json)
  }

  @Test("Execute rejects public database")
  internal func rejectsPublicDatabase() async throws {
    let baseConfig = try await MistDemoConfig(
      database: .public(.prefers(.serverToServer))
    )
    let config = ListZonesConfig(base: baseConfig)
    let command = ListZonesCommand(config: config)

    await #expect(throws: ListZonesError.self) {
      try await command.execute()
    }
  }
}
