//
//  FetchAllRecordZoneChangesPhase.swift
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

/// Exercises
/// ``CloudKitService/fetchAllRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:maxPages:database:)``
/// on the custom zone provisioned by ``FetchRecordZoneChangesPhase``, then
/// tears the zone down.
internal struct FetchAllRecordZoneChangesPhase: IntegrationPhase {
  internal typealias Input = ChangeTrackingZoneSlot
  internal typealias Output = NoState

  internal static let title = "Fetch all record zone changes"
  internal static let emoji = "📚"
  internal static let apiName = "fetchAllRecordZoneChanges"

  internal func run(
    input: ChangeTrackingZoneSlot,
    context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    do {
      let result = try await context.service.fetchAllRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: input.zoneID)],
        database: context.database
      )

      try ChangeTrackingVerification.requireNoZoneFailures(
        result.failures,
        operation: Self.apiName
      )

      let expectedNames = Set(input.recordNames)
      let foundNames = ChangeTrackingVerification.recordNames(in: result.changes)
      print(
        "✅ Fetched changes for \(result.changes.count) zone(s), \(foundNames.count) record(s)"
      )

      if !ChangeTrackingVerification.warnIfChangeFeedEmpty(
        foundCount: foundNames.count,
        expectedNames: expectedNames
      ) {
        let matched = expectedNames.intersection(foundNames)
        if context.verbose {
          print("   Found \(matched.count) of \(expectedNames.count) zone record(s)")
          for zone in result.changes where zone.moreComing {
            print(
              "   ⚠️  Zone '\(zone.zone.zoneName)' still reports moreComing after fetch-all"
            )
          }
        }
      }

      try await ChangeTrackingVerification.deleteCustomZone(input, context: context)
      return NoState()
    } catch {
      try? await ChangeTrackingVerification.deleteCustomZone(input, context: context)
      throw error
    }
  }
}
