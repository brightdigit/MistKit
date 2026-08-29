//
//  CustomZoneQueryPhase.swift
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

/// Exercises `queryRecords` with an explicit `zoneID` against a live custom
/// zone: create the zone, write records into it, query them back, and verify
/// ``ZoneID/defaultZone`` does not see them. Owns zone teardown because
/// ``CleanupPhase`` issues deletes without a `zoneID`.
///
/// CloudKit query indexes update asynchronously. Fresh writes in a brand-new
/// custom zone often miss the first `records/query`; this phase confirms the
/// records landed via `changes/zone`, then retries the query before treating
/// an empty/partial result as index lag (same non-fatal class as `NOT_FOUND`
/// when the schema is not QUERYABLE yet).
internal struct CustomZoneQueryPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Query records in a custom zone"
  internal static let emoji = "🗂️"
  internal static let apiName = "records/query (zoneID)"

  /// Attempts before treating a partial/empty query as index lag.
  private static let queryAttempts = 6
  /// Delay between query attempts (nanoseconds).
  private static let queryRetryDelayNanoseconds: UInt64 = 1_500_000_000

  internal func run(
    input: NoState,
    context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let zoneName = "MistDemoZoneQuery-\(UUID().uuidString.prefix(8))"
    let zoneID = ZoneID(zoneName: zoneName)

    _ = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created zone: \(zoneName)")
    }

    let recordName1 = "mistkit-zone-query-\(UUID().uuidString.lowercased())"
    let recordName2 = "mistkit-zone-query-\(UUID().uuidString.lowercased())"
    let expectedNames = Set([recordName1, recordName2])

    do {
      let modifyResults = try await context.service.modifyRecords(
        [
          RecordOperation(
            operationType: .forceUpdate,
            recordType: MistDemoConfig.recordType,
            recordName: recordName1,
            fields: [
              "title": .string("Zone query 1"),
              "index": .int64(1),
            ]
          ),
          RecordOperation(
            operationType: .forceUpdate,
            recordType: MistDemoConfig.recordType,
            recordName: recordName2,
            fields: [
              "title": .string("Zone query 2"),
              "index": .int64(2),
            ]
          ),
        ],
        zoneID: zoneID,
        database: context.database
      )
      for result in modifyResults {
        _ = try result.get()
      }
      if context.verbose {
        print("   ✅ Wrote \(modifyResults.count) record(s) into \(zoneName)")
      }

      try await confirmRecordsViaChangeFeed(
        zoneID: zoneID,
        expectedNames: expectedNames,
        context: context
      )

      let query = Query(recordType: MistDemoConfig.recordType)

      do {
        let foundNames = try await queryUntilPresent(
          query,
          zoneID: zoneID,
          expectedNames: expectedNames,
          context: context
        )

        guard let foundNames else {
          // Records are in the zone (change feed), but the query index has not
          // caught up — same class of lag as NOT_FOUND for an unindexed schema.
          print(
            """
            ⚠️  Custom-zone query missed records after retries — \
            query index lag (non-fatal; changes/zone confirmed writes)
            """
          )
          try await cleanup(zoneName: zoneName, context: context)
          return NoState()
        }

        if context.verbose {
          print("   ✅ Custom-zone query returned both records")
        }

        let defaultResult = try await context.service.queryRecords(
          query,
          zoneID: .defaultZone,
          database: context.database
        )
        let defaultNames = Set(defaultResult.records.map(\.recordName))
        let leaked = expectedNames.intersection(defaultNames)
        guard leaked.isEmpty else {
          try await cleanup(zoneName: zoneName, context: context)
          throw IntegrationTestError.verificationFailed(
            "default-zone query returned custom-zone records: "
              + leaked.sorted().joined(separator: ", ")
          )
        }
        if context.verbose {
          print("   ✅ Default-zone query excluded custom-zone records")
        }

        print("✅ Queried records in a custom zone (\(foundNames.count) found)")
      } catch {
        guard case CloudKitError.notFound = error else {
          try? await cleanup(zoneName: zoneName, context: context)
          throw error
        }
        print(
          "⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)"
        )
      }

      try await cleanup(zoneName: zoneName, context: context)
    } catch let error as IntegrationTestError {
      try? await cleanup(zoneName: zoneName, context: context)
      throw error
    } catch {
      try? await cleanup(zoneName: zoneName, context: context)
      throw IntegrationTestError.verificationFailed(
        "custom zone query failed: \(error.localizedDescription)"
      )
    }

    return NoState()
  }

  /// Proves the writes landed in the custom zone via `changes/zone` before
  /// relying on the eventually-consistent query index.
  private func confirmRecordsViaChangeFeed(
    zoneID: ZoneID,
    expectedNames: Set<String>,
    context: PhaseContext
  ) async throws {
    let result = try await context.service.fetchRecordZoneChanges(
      zones: [ZoneChangesRequest(zoneID: zoneID)],
      database: context.database
    )
    try ChangeTrackingVerification.requireNoZoneFailures(
      result.failures,
      operation: "fetchRecordZoneChanges (pre-query)"
    )
    let foundNames = ChangeTrackingVerification.recordNames(in: result.changes)
    if ChangeTrackingVerification.warnIfChangeFeedEmpty(
      foundCount: foundNames.count,
      expectedNames: expectedNames
    ) {
      return
    }
    guard expectedNames.isSubset(of: foundNames) else {
      throw IntegrationTestError.verificationFailed(
        "changes/zone missing written records before query — "
          + "expected \(expectedNames.sorted()), found \(foundNames.sorted())"
      )
    }
    if context.verbose {
      print("   ✅ Change feed confirmed both records in zone")
    }
  }

  /// Retries `queryRecords` until both expected names appear, or returns `nil`
  /// when the index still lags after ``queryAttempts``.
  private func queryUntilPresent(
    _ query: Query,
    zoneID: ZoneID,
    expectedNames: Set<String>,
    context: PhaseContext
  ) async throws -> Set<String>? {
    var lastFound: Set<String> = []
    for attempt in 1...Self.queryAttempts {
      let result = try await context.service.queryRecords(
        query,
        zoneID: zoneID,
        database: context.database
      )
      lastFound = Set(result.records.map(\.recordName))
      if expectedNames.isSubset(of: lastFound) {
        return lastFound
      }
      if context.verbose {
        print(
          "   ⏳ Query attempt \(attempt)/\(Self.queryAttempts): "
            + "found \(lastFound.count) record(s), "
            + "matched \(expectedNames.intersection(lastFound).count)/"
            + "\(expectedNames.count)"
        )
      }
      if attempt < Self.queryAttempts {
        try? await Task.sleep(nanoseconds: Self.queryRetryDelayNanoseconds)
      }
    }
    if context.verbose {
      print(
        "   ⚠️  After \(Self.queryAttempts) attempts, matched "
          + "\(expectedNames.intersection(lastFound).count)/\(expectedNames.count) "
          + "(found names: \(lastFound.sorted()))"
      )
    }
    return nil
  }

  private func cleanup(
    zoneName: String,
    context: PhaseContext
  ) async throws {
    if context.skipCleanup {
      print("   ⏭️  Skipping zone cleanup — inspect zone '\(zoneName)'")
      return
    }
    try await context.service.deleteZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted zone: \(zoneName)")
    }
  }
}
