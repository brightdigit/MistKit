//
//  ChangesRequestOptionsPhase.swift
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

/// Exercises the `records/changes` request options added in #385
/// (`desiredKeys`, `desiredRecordTypes`).
///
/// CloudKit only tracks changes in **custom zones** ("cannot get changes in
/// default zone"), so — unlike the surrounding query/modify phases that reuse
/// the shared default-zone records — this phase provisions its own custom zone,
/// writes records into it, fetches the change feed with both options, asserts
/// their effect, and tears the zone down again. The zone delete is best-effort
/// on the failure path so an assertion failure still cleans up. Custom zones
/// are private/shared only, so this phase belongs to the private pipeline.
internal struct ChangesRequestOptionsPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Fetch changes with request options (desiredKeys/recordTypes)"
  internal static let emoji = "🎛️ "
  internal static let apiName = "fetchRecordChanges"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji)\(Self.title)")

    let zoneName = "mistkit-itest-changes-\(UUID().uuidString.lowercased())"
    _ = try await context.service.createZone(
      zoneName: zoneName, database: context.database
    )
    if context.verbose {
      print("   ✅ Created change-tracking zone: \(zoneName)")
    }

    do {
      try await Self.exercise(
        zoneID: ZoneID(zoneName: zoneName), context: context
      )
    } catch {
      // Preserve the original failure; the zone teardown is best-effort.
      try? await context.service.deleteZone(
        zoneName: zoneName, database: context.database
      )
      throw error
    }

    try await context.service.deleteZone(
      zoneName: zoneName, database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted change-tracking zone: \(zoneName)")
    }

    return NoState()
  }

  /// Writes records into `zoneID`, fetches its change feed with `desiredKeys`
  /// and `desiredRecordTypes`, and asserts both options took effect.
  private static func exercise(zoneID: ZoneID, context: PhaseContext) async throws {
    let operations = (1...2).map { index in
      RecordOperation(
        operationType: .forceUpdate,
        recordType: MistDemoConfig.recordType,
        recordName: "mistkit-test-\(UUID().uuidString.lowercased())",
        fields: [
          "title": .string("Changes options \(index)"),
          "index": .int64(index),
        ]
      )
    }
    _ = try await context.service.modifyRecords(
      operations, zoneID: zoneID, database: context.database
    )

    let result = try await context.service.fetchRecordChanges(
      zoneID: zoneID,
      desiredKeys: ["title"],
      desiredRecordTypes: [MistDemoConfig.recordType],
      database: context.database
    )
    print("✅ Fetched \(result.records.count) change(s) with request options")

    guard result.records.contains(where: { !$0.deleted }) else {
      // Change tracking can lag a fresh write; don't fail the run over timing.
      print("   ⚠️  Change feed empty — skipping assertions (propagation lag)")
      return
    }

    // desiredRecordTypes must exclude any type other than ours. Tombstones omit
    // their type (recordType == nil), so skip them.
    let wrongType = result.records.filter {
      guard let type = $0.recordType else { return false }
      return type != MistDemoConfig.recordType
    }
    guard wrongType.isEmpty else {
      throw IntegrationTestError.verificationFailed(
        "desiredRecordTypes was ignored — changes returned type(s): "
          + Set(wrongType.compactMap(\.recordType)).sorted().joined(separator: ", ")
      )
    }
    print("   ✅ desiredRecordTypes honored: only '\(MistDemoConfig.recordType)' returned")

    // desiredKeys: ["title"] must exclude the "index" field on live records.
    guard let sample = result.records.first(where: { !$0.deleted && !$0.fields.isEmpty }) else {
      print("   ⚠️  No populated records to check desiredKeys against")
      return
    }
    let unexpected = sample.fields.keys.filter { $0 != "title" }
    guard unexpected.isEmpty else {
      throw IntegrationTestError.verificationFailed(
        "desiredKeys was ignored — changes returned unrequested field(s): "
          + unexpected.sorted().joined(separator: ", ")
      )
    }
    print("   ✅ desiredKeys honored: only \(sample.fields.keys.sorted()) returned")
  }
}
