//
//  ModifyZonesCommandTests.swift
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

@Suite("ModifyZonesCommand Tests")
internal struct ModifyZonesCommandTests {
  @Test("Command has correct static properties")
  internal func staticProperties() {
    #expect(ModifyZonesCommand.commandName == "modify-zones")
    #expect(ModifyZonesCommand.abstract == "Create or delete CloudKit zones")
    #expect(ModifyZonesCommand.helpText.contains("MODIFY-ZONES"))
  }

  @Test("Config initializes with operations")
  internal func configWithOperations() async throws {
    let baseConfig = try await MistDemoConfig()
    let ops = [
      ZoneOperationInput(type: "create", zoneName: "Articles"),
      ZoneOperationInput(type: "delete", zoneName: "Archive"),
    ]
    let config = ModifyZonesConfig(base: baseConfig, operations: ops)
    #expect(config.operations.count == 2)
    #expect(config.output == .json)
  }

  @Test("Parse envelope with create + delete")
  internal func parseEnvelopeMixed() throws {
    let json = """
      {
        "operations": [
          { "type": "create", "zoneName": "Articles" },
          { "type": "delete", "zoneName": "Archive" }
        ]
      }
      """
    let data = Data(json.utf8)
    let ops = try ModifyZonesConfig.parseOperations(from: data)
    #expect(ops.count == 2)
    #expect(ops[0] == ZoneOperationInput(type: "create", zoneName: "Articles"))
    #expect(ops[1] == ZoneOperationInput(type: "delete", zoneName: "Archive"))
  }

  @Test("Parse invalid JSON throws parsingFailed")
  internal func parseInvalidJSONThrows() throws {
    let data = Data("{ not json".utf8)
    #expect(throws: ModifyZonesError.self) {
      _ = try ModifyZonesConfig.parseOperations(from: data)
    }
  }

  @Test("ZoneOperationInput.create maps to .create")
  internal func zoneOperationCreate() throws {
    let input = ZoneOperationInput(type: "create", zoneName: "Articles")
    let operation = try input.toZoneOperation()
    if case .create(let zoneID) = operation {
      #expect(zoneID.zoneName == "Articles")
    } else {
      Issue.record("Expected .create, got \(operation)")
    }
  }

  @Test("ZoneOperationInput.delete maps to .delete")
  internal func zoneOperationDelete() throws {
    let input = ZoneOperationInput(type: "delete", zoneName: "Archive")
    let operation = try input.toZoneOperation()
    if case .delete(let zoneID) = operation {
      #expect(zoneID.zoneName == "Archive")
    } else {
      Issue.record("Expected .delete, got \(operation)")
    }
  }

  @Test("ZoneOperationInput rejects unknown type")
  internal func zoneOperationUnknownType() {
    let input = ZoneOperationInput(type: "weirdtype", zoneName: "X")
    #expect(throws: ModifyZonesError.self) {
      _ = try input.toZoneOperation()
    }
  }

  @Test("ZoneOperationInput rejects empty zone name")
  internal func zoneOperationEmptyName() {
    let input = ZoneOperationInput(type: "create", zoneName: "   ")
    #expect(throws: ModifyZonesError.self) {
      _ = try input.toZoneOperation()
    }
  }

  @Test("Execute rejects public database")
  internal func rejectsPublicDatabase() async throws {
    let baseConfig = try await MistDemoConfig(
      database: .public(.prefers(.serverToServer))
    )
    let config = ModifyZonesConfig(
      base: baseConfig,
      operations: [ZoneOperationInput(type: "create", zoneName: "X")]
    )
    let command = ModifyZonesCommand(config: config)

    await #expect(throws: ModifyZonesError.self) {
      try await command.execute()
    }
  }
}
