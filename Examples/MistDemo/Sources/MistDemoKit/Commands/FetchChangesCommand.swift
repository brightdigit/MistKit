//
//  FetchChangesCommand.swift
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

import Foundation
import MistKit

/// Command to fetch record changes with incremental sync
public struct FetchChangesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = FetchChangesConfig
  /// The command name.
  public static let commandName = "fetch-changes"
  /// The command abstract.
  public static let abstract =
    "Fetch record changes with incremental sync"
  /// The command help text.
  public static let helpText = """
    FETCH-CHANGES - Fetch record changes

    USAGE:
      mistdemo fetch-changes [options]

    OPTIONS:
      --sync-token <token>     Sync token from previous fetch
      --zone <name>            Zone name (default: _defaultZone)
      --fetch-all              Auto-paginate all changes
      --limit <count>          Max results per page (1-200)
      --database <type>        Database to target
      --output-format <format> Output format

    EXAMPLES:
      mistdemo fetch-changes
      mistdemo fetch-changes --fetch-all
      mistdemo fetch-changes --sync-token "token"

    NOTES:
      Save the returned sync token for next fetch.
    """

  private let config: FetchChangesConfig

  /// Creates a new instance.
  public init(config: FetchChangesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔄 Fetch Record Changes")
    print(String(repeating: "=", count: 60))

    let service = try MistKitClientFactory.create(
      for: config.base
    )
    let zoneID = ZoneID(zoneName: config.zone, ownerName: nil)

    printSyncTokenStatus()

    if config.fetchAll {
      try await fetchAllChanges(service: service, zoneID: zoneID)
    } else {
      try await fetchSinglePage(service: service, zoneID: zoneID)
    }

    print("\n" + String(repeating: "=", count: 60))
    print("✅ Fetch completed!")
    print(String(repeating: "=", count: 60))
  }

  private func printSyncTokenStatus() {
    if let token = config.syncToken {
      print("   Using sync token: \(token.prefix(20))...")
    } else {
      print("   Performing initial fetch (no sync token)")
    }
  }

  private func fetchAllChanges(
    service: CloudKitService, zoneID: ZoneID
  ) async throws {
    print("\n📦 Fetching all changes (automatic pagination)...")
    let (records, newToken) = try await service.fetchAllRecordChanges(
      zoneID: zoneID,
      syncToken: config.syncToken,
      database: config.base.database
    )
    print("\n✅ Fetched \(records.count) record(s)")
    displayRecords(records, limit: 5)
    if let token = newToken {
      print("\n💾 New sync token: \(token.prefix(20))...")
      print("   mistdemo fetch-changes --sync-token '\(token)'")
    }
  }

  private func fetchSinglePage(
    service: CloudKitService, zoneID: ZoneID
  ) async throws {
    print("\n📄 Fetching single page...")
    let result = try await service.fetchRecordChanges(
      zoneID: zoneID,
      syncToken: config.syncToken,
      resultsLimit: config.limit ?? 10,
      database: config.base.database
    )
    print("\n✅ Fetched \(result.records.count) record(s)")
    displayRecords(result.records, limit: 5)

    if result.moreComing, let token = result.syncToken {
      print("\n⚠️  More changes available!")
      print("   mistdemo fetch-changes --sync-token '\(token)'")
    }

    if let token = result.syncToken {
      print("\n💾 Sync token: \(token.prefix(20))...")
    }
  }

  private func displayRecords(_ records: [RecordInfo], limit: Int) {
    let displayed = records.prefix(limit)
    for record in displayed {
      print("   📝 \(record.recordType) - \(record.recordName)")
      if !record.fields.isEmpty {
        print("      Fields: \(record.fields.keys.joined(separator: ", "))")
      }
    }
    if records.count > limit {
      print("   ... and \(records.count - limit) more")
    }
  }
}
