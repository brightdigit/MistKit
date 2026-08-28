//
//  FetchRecordZoneChangesPhase.swift
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
/// ``CloudKitService/fetchRecordZoneChanges(zones:reverse:desiredKeys:resultsLimit:desiredRecordTypes:database:)``
/// against a live custom zone. CloudKit rejects `changes/zone` on
/// `_defaultZone`, so this phase provisions its own zone and records rather
/// than reusing the default-zone records created earlier in the pipeline.
internal struct FetchRecordZoneChangesPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = ChangeTrackingZoneSlot

  internal static let title = "Fetch record zone changes"
  internal static let emoji = "📁"
  internal static let apiName = "fetchRecordZoneChanges"

  internal func run(
    input: NoState,
    context: PhaseContext
  ) async throws -> ChangeTrackingZoneSlot {
    print("\n\(Self.emoji) \(Self.title)")

    let slot = try await ChangeTrackingVerification.provisionCustomZone(
      context: context
    )

    do {
      let result = try await context.service.fetchRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: slot.zoneID)],
        database: context.database
      )

      try ChangeTrackingVerification.requireNoZoneFailures(
        result.failures,
        operation: Self.apiName
      )

      let expectedNames = Set(slot.recordNames)
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
        }
      }

      return slot
    } catch {
      try? await ChangeTrackingVerification.deleteCustomZone(slot, context: context)
      throw error
    }
  }
}
