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
/// against a live container. Follows up on ``FetchZoneChangesPhase``, which
/// reports *which* zones changed; this phase fetches the record changes
/// inside `_defaultZone`. Failures are non-fatal, matching the sibling
/// database-changes phases.
internal struct FetchRecordZoneChangesPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Fetch record zone changes"
  internal static let emoji = "📁"
  internal static let apiName = "fetchRecordZoneChanges"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    do {
      let result = try await context.service.fetchRecordZoneChanges(
        zones: [ZoneChangesRequest(zoneID: ZoneID.defaultZone)],
        database: context.database
      )
      print("✅ Fetched changes for \(result.changes.count) zone(s)")
      if context.verbose {
        for change in result.changes {
          print("   - \(change.zone.zoneName): \(change.records.count) record(s)")
        }
        for failure in result.failures {
          print("   ⚠️  \(failure.zoneName): \(failure.serverErrorCode)")
        }
      }
    } catch {
      print("⚠️  fetchRecordZoneChanges failed (non-fatal): \(error)")
    }

    return NoState()
  }
}
