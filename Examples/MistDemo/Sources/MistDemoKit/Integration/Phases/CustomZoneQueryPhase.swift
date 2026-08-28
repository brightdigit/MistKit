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
internal struct CustomZoneQueryPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Query records in a custom zone"
  internal static let emoji = "🗂️"
  internal static let apiName = "records/query (zoneID)"

  internal func run(
    input: NoState,
    context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let zoneName = "MistDemoZoneQuery-\(UUID().uuidString.prefix(8))"
    let zoneID = ZoneID(zoneName: zoneName, ownerName: nil)

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
      _ = try await context.service.modifyRecords(
        [
          .create(
            recordType: MistDemoConfig.recordType,
            recordName: recordName1,
            fields: [
              "title": .string("Zone query 1"),
              "index": .int64(1),
            ]
          ),
          .create(
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

      let query = Query(recordType: MistDemoConfig.recordType)

      do {
        let result = try await context.service.queryRecords(
          query,
          zoneID: zoneID,
          database: context.database
        )
        let foundNames = Set(result.records.map(\.recordName))
        guard expectedNames.isSubset(of: foundNames) else {
          try await cleanup(zoneName: zoneName, context: context)
          throw IntegrationTestError.verificationFailed(
            "zone query did not return both created records"
          )
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
      print("✅ Queried records in a custom zone")
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
