//
//  ListZonesCommand.swift
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

/// Command that lists all zones in the configured database.
public struct ListZonesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ListZonesConfig
  /// The command name.
  public static let commandName = "list-zones"
  /// The command abstract.
  public static let abstract = "List all zones in the database"
  /// The command help text.
  public static let helpText = """
    LIST-ZONES - List all zones in the database

    USAGE:
      mistdemo list-zones [options]

    OPTIONS:
      --database <type>              Database to target (private, shared)
      --zones-include-default        Include `_defaultZone` in the output
      --output-format <format>       Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo list-zones --database private
      mistdemo list-zones --database shared --zones-include-default

    NOTES:
      - Only `private` and `shared` databases support zone listing.
      - By default the default zone (`_defaultZone`) is filtered out so
        only custom zones are shown.
    """

  private let config: ListZonesConfig

  /// Creates a new instance.
  public init(config: ListZonesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    if case .public = config.base.database {
      throw ListZonesError.databaseNotSupported
    }

    let service = try MistKitClientFactory.create(for: config.base)
    let zones = try await service.listZones(database: config.base.database)

    let filtered =
      config.includeDefault
      ? zones
      : zones.filter { $0.zoneName != ZoneID.defaultZone.zoneName }

    try await outputResults(filtered, format: config.output)
  }
}
