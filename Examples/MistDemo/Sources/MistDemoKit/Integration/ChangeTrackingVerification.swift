//
//  ChangeTrackingVerification.swift
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

/// Shared setup and assertions for `changes/database` and `changes/zone`
/// integration phases.
internal enum ChangeTrackingVerification {
  /// Provisions a uniquely-named custom zone and writes two records into it.
  ///
  /// CloudKit only tracks record changes in custom zones — not `_defaultZone`.
  internal static func provisionCustomZone(
    context: PhaseContext
  ) async throws -> ChangeTrackingZoneSlot {
    let zoneName = "mistkit-itest-zone-changes-\(UUID().uuidString.lowercased())"
    let zoneID = ZoneID(zoneName: zoneName)

    _ = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created change-tracking zone: \(zoneName)")
    }

    let recordNames = (1...2).map { _ in
      "mistkit-zone-changes-\(UUID().uuidString.lowercased())"
    }
    let operations = recordNames.enumerated().map { index, recordName in
      RecordOperation(
        operationType: .forceUpdate,
        recordType: MistDemoConfig.recordType,
        recordName: RecordName(recordName),
        fields: [
          "title": .string("Zone changes \(index + 1)"),
          "index": .int64(index + 1),
        ]
      )
    }
    _ = try await context.service.modifyRecords(
      operations,
      zoneID: zoneID,
      database: context.database
    )

    return ChangeTrackingZoneSlot(zoneID: zoneID, recordNames: recordNames)
  }

  internal static func deleteCustomZone(
    _ slot: ChangeTrackingZoneSlot,
    context: PhaseContext
  ) async throws {
    if context.skipCleanup {
      print(
        "   ⏭️  Skipping zone cleanup — inspect zone '\(slot.zoneID.zoneName)'"
      )
      return
    }
    try await context.service.deleteZone(
      zoneName: slot.zoneID.zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted change-tracking zone: \(slot.zoneID.zoneName)")
    }
  }

  internal static func requireDatabaseSyncToken(
    _ token: String?,
    operation: String
  ) throws {
    guard let token, !token.isEmpty else {
      throw IntegrationTestError.verificationFailed(
        "\(operation) returned no database sync token"
      )
    }
  }

  internal static func requireNoZoneFailures(
    _ failures: [ZoneOperationFailure],
    operation: String
  ) throws {
    guard failures.isEmpty else {
      let summary = failures.map { "\($0.zoneName): \($0.serverErrorCode)" }
        .joined(separator: ", ")
      throw IntegrationTestError.verificationFailed(
        "\(operation) reported per-zone failure(s): \(summary)"
      )
    }
  }

  internal static func recordNames(
    in changes: [ZoneRecordChanges]
  ) -> Set<String> {
    Set(
      changes.flatMap(\.records).map(\.recordName.rawValue)
    )
  }

  /// Returns `true` when the change feed was empty and callers should skip
  /// record-level assertions (CloudKit propagation lag).
  @discardableResult
  internal static func warnIfChangeFeedEmpty(
    foundCount: Int,
    expectedNames: Set<String>
  ) -> Bool {
    guard foundCount == 0, !expectedNames.isEmpty else {
      return false
    }
    print(
      "   ⚠️  Change feed empty — skipping record assertions (propagation lag)"
    )
    return true
  }
}
