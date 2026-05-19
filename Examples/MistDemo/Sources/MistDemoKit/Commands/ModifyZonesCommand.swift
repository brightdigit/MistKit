//
//  ModifyZonesCommand.swift
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

internal import Foundation
internal import MistKit

/// Command that creates or deletes zones.
public struct ModifyZonesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ModifyZonesConfig
  /// The command name.
  public static let commandName = "modify-zones"
  /// The command abstract.
  public static let abstract = "Create or delete CloudKit zones"
  /// The command help text.
  public static let helpText = """
    MODIFY-ZONES - Create or delete CloudKit zones

    USAGE:
      mistdemo modify-zones --operations-file <path> [options]
      cat zones.json | mistdemo modify-zones --stdin [options]

    INPUT (choose one):
      --operations-file <path>       Path to JSON envelope
      --stdin                        Read JSON envelope from stdin

    OPTIONS:
      --database <type>              Database to target (private, shared)
      --output-format <format>       Output format (json, table, csv, yaml)

    INPUT FORMAT:
      {
        "operations": [
          { "type": "create", "zoneName": "Articles" },
          { "type": "delete", "zoneName": "Archive"  }
        ]
      }

    NOTES:
      - Only `private` and `shared` databases support zone modification.
      - Each delete is announced on stderr before the request is sent.
    """

  private let config: ModifyZonesConfig

  /// Creates a new instance.
  public init(config: ModifyZonesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    if case .public = config.base.database {
      throw ModifyZonesError.databaseNotSupported
    }

    let service = try MistKitClientFactory.create(for: config.base)

    let operations = try config.operations.map { input -> ZoneOperation in
      let operation = try input.toZoneOperation()
      if case .delete(let zoneID) = operation {
        let warning = "⚠️  Deleting zone '\(zoneID.zoneName)'\n"
        FileHandle.standardError.write(Data(warning.utf8))
      }
      return operation
    }

    let results = try await service.modifyZones(
      operations,
      database: config.base.database
    )

    try await outputResults(results, format: config.output)
  }
}
