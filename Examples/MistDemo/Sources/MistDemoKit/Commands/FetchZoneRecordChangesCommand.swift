//
//  FetchZoneRecordChangesCommand.swift
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

/// Command to fetch record changes within one or more CloudKit zones.
///
/// Wraps `changes/zone`. Typically paired with `fetch-database-changes`,
/// which reports *which* zones changed; this command fetches the record
/// changes inside them. Each zone paginates independently.
public struct FetchZoneRecordChangesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = FetchZoneRecordChangesConfig
  /// The command name.
  public static let commandName = "fetch-zone-record-changes"
  /// The command abstract.
  public static let abstract =
    "Fetch record changes within one or more CloudKit zones"
  /// The command help text.
  public static let helpText = """
    FETCH-ZONE-RECORD-CHANGES - Fetch record changes within zones

    USAGE:
      mistdemo fetch-zone-record-changes [options]

    OPTIONS:
      --zone-names <names>     Comma-separated zone names (default: _defaultZone)
      --sync-token <token>     Sync token applied to every requested zone
      --fetch-all              Auto-paginate all changes (per zone)
      --limit <count>          Max results per zone per page (1-200)
      --fields <fields>        Comma-separated fields (desiredKeys)
      --record-types <types>   Comma-separated record types to include
      --database <type>        Database to target
      --output-format <format> Output format

    EXAMPLES:
      mistdemo fetch-zone-record-changes
      mistdemo fetch-zone-record-changes --zone-names "Articles,Photos"
      mistdemo fetch-zone-record-changes --fetch-all

    NOTES:
      Each zone paginates independently — a sync token and moreComing
      flag are returned per zone rather than once for the whole request.
    """

  private let config: FetchZoneRecordChangesConfig

  /// Creates a new instance.
  public init(config: FetchZoneRecordChangesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔄 Fetch Zone Record Changes")
    print(String(repeating: "=", count: 60))

    let service = try MistKitClientFactory.create(
      for: config.base
    )
    let zones = config.zones.map {
      ZoneChangesRequest(
        zoneID: ZoneID(zoneName: $0, ownerName: nil),
        syncToken: config.syncToken,
        desiredKeys: config.desiredKeys,
        resultsLimit: config.limit,
        desiredRecordTypes: config.desiredRecordTypes
      )
    }

    print("\n📋 Requesting changes for \(zones.count) zone(s):")
    for name in config.zones {
      print("   - \(name)")
    }

    if config.fetchAll {
      try await fetchAllChanges(service: service, zones: zones)
    } else {
      try await fetchSinglePage(service: service, zones: zones)
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Fetch completed!")
    print(String(repeating: "=", count: 60))
  }

  private func fetchAllChanges(
    service: CloudKitService, zones: [ZoneChangesRequest]
  ) async throws {
    print("\n📦 Fetching all zone record changes (automatic pagination)...")
    let result = try await service.fetchAllRecordZoneChanges(
      zones: zones,
      database: config.base.database
    )
    displayResult(result)
  }

  private func fetchSinglePage(
    service: CloudKitService, zones: [ZoneChangesRequest]
  ) async throws {
    print("\n📄 Fetching single page for each zone...")
    let result = try await service.fetchRecordZoneChanges(
      zones: zones,
      database: config.base.database
    )
    displayResult(result)
  }

  private func displayResult(_ result: RecordZoneChangesResult) {
    print("\n✅ Fetched changes for \(result.changes.count) zone(s)")
    for change in result.changes {
      print("   📁 \(change.zone.zoneName): \(change.records.count) record(s)")
      if let token = change.syncToken {
        print("      Sync token: \(token.prefix(20))...")
      }
      if change.moreComing {
        print("      ⚠️  More changes available for this zone")
      }
    }

    if !result.failures.isEmpty {
      print("\n⚠️  \(result.failures.count) zone failure(s):")
      for failure in result.failures {
        print("   - \(failure.zoneName): \(failure.serverErrorCode)")
      }
    }

    print("\n   Overall more coming: \(result.moreComing)")
  }
}
