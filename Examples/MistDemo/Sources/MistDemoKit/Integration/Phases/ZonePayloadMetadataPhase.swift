//
//  ZonePayloadMetadataPhase.swift
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

/// Live verification for issue #444: zone list/lookup responses carry
/// `ownerRecordName` and `zoneType`, and `changes/database` surfaces zone
/// deletions via `deleted`.
///
/// Creates a uniquely-named custom zone, asserts the metadata round-trips on
/// `lookupZones` / `listZones`, then deletes the zone and polls
/// `fetchDatabaseChanges` for a `deleted: true` tombstone.
internal struct ZonePayloadMetadataPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Zone payload metadata (ownerRecordName, zoneType, deleted)"
  internal static let emoji = "🏷️"
  internal static let apiName = "zonePayloadMetadata"

  private static let customZoneType = "REGULAR_CUSTOM_ZONE"
  private static let changeFeedPollAttempts = 5
  private static let changeFeedPollDelay: Duration = .seconds(2)

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let zoneName = "mistkit-zone-payload-\(UUID().uuidString.lowercased())"
    let zoneID = ZoneID(zoneName: zoneName)

    let baseline = try await context.service.fetchDatabaseChanges(
      database: context.database
    )
    try ChangeTrackingVerification.requireNoZoneFailures(
      baseline.failures,
      operation: "fetchDatabaseChanges (baseline)"
    )

    do {
      let created = try await context.service.createZone(
        zoneName: zoneName,
        database: context.database
      )
      if context.verbose {
        print("   ✅ Created zone: \(created.zoneName)")
      }

      let lookedUp = try await context.service.lookupZones(
        zoneIDs: [zoneID],
        database: context.database
      )
      guard let lookupZone = lookedUp.first(where: { $0.zoneName == zoneName }) else {
        throw IntegrationTestError.verificationFailed(
          "lookupZones did not return the created zone '\(zoneName)'"
        )
      }
      try Self.requireLiveZoneMetadata(lookupZone, source: "lookupZones")

      let listed = try await context.service.listZones(database: context.database)
      guard let listZone = listed.first(where: { $0.zoneName == zoneName }) else {
        throw IntegrationTestError.verificationFailed(
          "listZones did not include the created zone '\(zoneName)'"
        )
      }
      try Self.requireLiveZoneMetadata(listZone, source: "listZones")

      let (createdChange, afterCreateDatabaseToken) = try await Self.pollDatabaseChanges(
        syncToken: baseline.syncToken,
        zoneName: zoneName,
        context: context,
        description: "zone creation"
      ) { !$0.deleted }
      try Self.requireLiveZoneMetadata(createdChange, source: "fetchDatabaseChanges (create)")

      try await context.service.deleteZone(
        zoneName: zoneName,
        database: context.database
      )
      if context.verbose {
        print("   ✅ Deleted zone: \(zoneName)")
      }

      let (deletedChange, _) = try await Self.pollDatabaseChanges(
        syncToken: afterCreateDatabaseToken ?? baseline.syncToken,
        zoneName: zoneName,
        context: context,
        description: "zone deletion tombstone"
      ) { $0.deleted }

      guard deletedChange.deleted else {
        throw IntegrationTestError.verificationFailed(
          "fetchDatabaseChanges did not mark '\(zoneName)' deleted after deleteZone"
        )
      }

      if context.verbose {
        print("   ✅ Change feed tombstone: deleted=true for \(zoneName)")
        if let owner = deletedChange.ownerRecordName {
          print("     Owner: \(owner)")
        }
        if let zoneType = deletedChange.zoneType {
          print("     Zone type: \(zoneType)")
        }
      }

      print("✅ Zone payload metadata verified for '\(zoneName)'")
      return NoState()
    } catch {
      try? await context.service.deleteZone(
        zoneName: zoneName,
        database: context.database
      )
      throw error
    }
  }

  private static func requireLiveZoneMetadata(
    _ zone: ZoneInfo,
    source: String
  ) throws {
    guard let owner = zone.ownerRecordName, !owner.isEmpty else {
      throw IntegrationTestError.verificationFailed(
        "\(source) omitted ownerRecordName for zone '\(zone.zoneName)'"
      )
    }
    guard zone.zoneType == customZoneType else {
      throw IntegrationTestError.verificationFailed(
        "\(source) reported zoneType '\(zone.zoneType ?? "nil")' for '\(zone.zoneName)' "
          + "(expected \(customZoneType))"
      )
    }
    guard !zone.deleted else {
      throw IntegrationTestError.verificationFailed(
        "\(source) reported deleted=true for live zone '\(zone.zoneName)'"
      )
    }
  }

  private static func pollDatabaseChanges(
    syncToken: String?,
    zoneName: String,
    context: PhaseContext,
    description: String,
    matching predicate: (ZoneInfo) -> Bool
  ) async throws -> (zone: ZoneInfo, databaseSyncToken: String?) {
    for attempt in 1...changeFeedPollAttempts {
      let result = try await context.service.fetchDatabaseChanges(
        syncToken: syncToken,
        database: context.database
      )
      try ChangeTrackingVerification.requireNoZoneFailures(
        result.failures,
        operation: "fetchDatabaseChanges (\(description))"
      )

      if let zone = result.changedZones.first(where: {
        $0.zoneName == zoneName && predicate($0)
      }) {
        return (zone, result.syncToken)
      }

      if attempt < changeFeedPollAttempts {
        if context.verbose {
          print(
            "   ⏳ Change feed empty for '\(zoneName)' (\(description)); "
              + "retrying (\(attempt)/\(changeFeedPollAttempts))…"
          )
        }
        try await Task.sleep(for: changeFeedPollDelay)
      }
    }

    throw IntegrationTestError.verificationFailed(
      "fetchDatabaseChanges never reported \(description) for zone '\(zoneName)' "
        + "after \(changeFeedPollAttempts) attempts"
    )
  }
}
