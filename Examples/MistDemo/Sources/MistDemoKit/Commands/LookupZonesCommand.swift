//
//  LookupZonesCommand.swift
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

/// Command to look up specific CloudKit zones by name
public struct LookupZonesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = LookupZonesConfig
  /// The command name.
  public static let commandName = "lookup-zones"
  /// The command abstract.
  public static let abstract = "Look up specific CloudKit zones by name"
  /// The command help text.
  public static let helpText = """
    LOOKUP-ZONES - Look up specific CloudKit zones

    USAGE:
      mistdemo lookup-zones [options]

    OPTIONS:
      --zone-names <names>       Zone names (default: _defaultZone)
      --database <type>          Database to target
      --output-format <format>   Output format

    EXAMPLES:
      mistdemo lookup-zones
      mistdemo lookup-zones --database private \\
        --zone-names "Articles,Photos"

    NOTES:
      - Auth method follows --database
      - Zone names are case-sensitive
    """

  private let config: LookupZonesConfig

  /// Creates a new instance.
  public init(config: LookupZonesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔍 Lookup CloudKit Zones")
    print(String(repeating: "=", count: 60))

    let service = try MistKitClientFactory.create(for: config.base)
    let zoneIDs = config.zoneNames.map { ZoneID(zoneName: $0, ownerName: nil) }

    print("\n📋 Looking up \(zoneIDs.count) zone(s):")
    for name in config.zoneNames {
      print("   - \(name)")
    }

    let zones = try await service.lookupZones(
      zoneIDs: zoneIDs,
      database: config.base.database
    )
    print("\n✅ Found \(zones.count) zone(s):")
    for zone in zones {
      print("   - \(zone.zoneName)")
      if let owner = zone.ownerRecordName {
        print("     Owner: \(owner)")
      }
      if !zone.capabilities.isEmpty {
        print("     Capabilities: \(zone.capabilities.joined(separator: ", "))")
      }
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Lookup completed!")
    print(String(repeating: "=", count: 60))
  }
}
