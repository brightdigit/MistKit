//
//  FetchDatabaseChangesCommand.swift
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

/// Command to fetch which record zones changed with incremental sync.
///
/// Wraps `changes/database`, the current replacement for the deprecated
/// `zones/changes` operation. Reports *which* zones changed; pair with
/// `fetch-zone-record-changes` to fetch the record changes inside them.
public struct FetchDatabaseChangesCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = FetchDatabaseChangesConfig
  /// The command name.
  public static let commandName = "fetch-database-changes"
  /// The command abstract.
  public static let abstract =
    "Fetch which record zones changed with incremental sync"
  /// The command help text.
  public static let helpText = """
    FETCH-DATABASE-CHANGES - Fetch database (zone-level) changes

    USAGE:
      mistdemo fetch-database-changes [options]

    OPTIONS:
      --sync-token <token>     Sync token from previous fetch
      --fetch-all              Auto-paginate all changes
      --limit <count>          Max zone changes per page
      --database <type>        Database to target
      --output-format <format> Output format

    EXAMPLES:
      mistdemo fetch-database-changes
      mistdemo fetch-database-changes --fetch-all
      mistdemo fetch-database-changes --sync-token "token"

    NOTES:
      Reports which zones changed; follow up with
      fetch-zone-record-changes to fetch the records inside them.
      Save the returned sync token for next fetch.
    """

  private let config: FetchDatabaseChangesConfig

  /// Creates a new instance.
  public init(config: FetchDatabaseChangesConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    print("\n" + String(repeating: "=", count: 60))
    print("🔄 Fetch Database Changes")
    print(String(repeating: "=", count: 60))

    let service = try MistKitClientFactory.create(
      for: config.base
    )

    printSyncTokenStatus()

    if config.fetchAll {
      try await fetchAllChanges(service: service)
    } else {
      try await fetchSinglePage(service: service)
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

  private func fetchAllChanges(service: CloudKitService) async throws {
    print("\n📦 Fetching all database changes (automatic pagination)...")
    let (zones, newToken) = try await service.fetchAllDatabaseChanges(
      syncToken: config.syncToken,
      resultsLimit: config.limit,
      database: config.base.database
    )
    print("\n✅ Fetched \(zones.count) changed zone(s)")
    displayZones(zones)
    if let token = newToken {
      print("\n💾 New sync token: \(token.prefix(20))...")
      print("   mistdemo fetch-database-changes --sync-token '\(token)'")
    }
  }

  private func fetchSinglePage(service: CloudKitService) async throws {
    print("\n📄 Fetching single page...")
    let result = try await service.fetchDatabaseChanges(
      syncToken: config.syncToken,
      resultsLimit: config.limit,
      database: config.base.database
    )
    print("\n✅ Fetched \(result.zones.count) zone change(s)")
    displayZones(result.zones)

    if result.moreComing, let token = result.syncToken {
      print("\n⚠️  More changes available!")
      print("   mistdemo fetch-database-changes --sync-token '\(token)'")
    }

    if let token = result.syncToken {
      print("\n💾 Sync token: \(token.prefix(20))...")
    }
    print("   More coming: \(result.moreComing)")
  }

  private func displayZones(_ zones: [ZoneChangeResult]) {
    let changed = zones.compactMap { result in
      if case .success(let zone) = result { return zone }
      return nil
    }
    for zone in changed.prefix(10) {
      print("   📁 \(zone.zoneName)")
    }
    if changed.count > 10 {
      print("   ... and \(changed.count - 10) more")
    }
    displayFailures(
      zones.compactMap { result in
        if case .failure(let failure) = result { return failure }
        return nil
      }
    )
  }

  private func displayFailures(_ failures: [ZoneOperationFailure]) {
    guard !failures.isEmpty else { return }
    print("\n⚠️  \(failures.count) zone failure(s):")
    for failure in failures {
      print("   - \(failure.zoneName): \(failure.serverErrorCode)")
    }
  }
}
