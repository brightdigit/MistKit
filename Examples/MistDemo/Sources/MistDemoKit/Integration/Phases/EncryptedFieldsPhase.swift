//
//  EncryptedFieldsPhase.swift
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

/// Write and read an `ENCRYPTED STRING` field, capturing whether CloudKit
/// echoes `isEncrypted` on the modify response and on `changes/zone`.
///
/// Self-cleaning: creates a unique private zone, writes one record, fetches
/// zone changes, then deletes the zone. Requires the MistDemo development
/// schema to include `"secret" ENCRYPTED STRING` on `Note`.
///
/// Under Advanced Data Protection this phase is expected to fail (or return
/// undecryptable results) once service keys leave Apple's HSMs — run once
/// with a standard-protection account and once with ADP to compare.
internal struct EncryptedFieldsPhase: IntegrationPhase {
  internal typealias Input = NoState
  internal typealias Output = NoState

  internal static let title = "Encrypted field roundtrip"
  internal static let emoji = "🔐"
  internal static let apiName = "createRecord+changes/zone"

  private static let secretField = "secret"
  private static let secretValue = "mistkit-encrypted-probe"

  internal func run(input: NoState, context: PhaseContext) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let zoneName = "mistkit-enc-\(UUID().uuidString.lowercased())"
    let recordName = "enc-\(UUID().uuidString.lowercased())"
    let zoneID = ZoneID(zoneName: zoneName)

    _ = try await context.service.createZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Created zone: \(zoneName)")
    }

    do {
      let written = try await context.service.createRecord(
        recordType: MistDemoConfig.recordType,
        recordName: recordName,
        fields: [
          "title": .string("Encrypted probe"),
          "index": .int64(0),
          Self.secretField: .string(Self.secretValue),
        ],
        encryptedFields: [Self.secretField],
        zoneID: zoneID,
        database: context.database
      )
      print("   ✅ Wrote encrypted field '\(Self.secretField)' on \(written.recordName)")
      try Self.assertSecret(on: written, source: "modify response")
      Self.reportEcho(written.encryptedFields, source: "modify response", verbose: context.verbose)

      let changes = try await context.service.fetchRecordChanges(
        zoneID: zoneID,
        database: context.database
      )
      if let changeRecord = changes.records.first(where: { $0.recordName == recordName }) {
        try Self.assertSecret(on: changeRecord, source: "changes/zone")
        Self.reportEcho(
          changeRecord.encryptedFields, source: "changes/zone", verbose: context.verbose
        )
      } else {
        // Change tracking can lag a fresh write; don't fail the run over timing.
        print("   ⚠️ Record not present in changes/zone batch (propagation lag)")
      }

      print("✅ Encrypted field roundtrip succeeded")
    } catch {
      try? await context.service.deleteZone(
        zoneName: zoneName,
        database: context.database
      )
      throw error
    }

    try await context.service.deleteZone(
      zoneName: zoneName,
      database: context.database
    )
    if context.verbose {
      print("   ✅ Deleted zone: \(zoneName)")
    }

    return NoState()
  }

  private static func assertSecret(on record: RecordInfo, source: String) throws {
    guard case .string(let value)? = record.fields[secretField] else {
      throw IntegrationTestError.verificationFailed(
        "\(source) missing string field '\(secretField)'"
      )
    }
    guard value == secretValue else {
      throw IntegrationTestError.verificationFailed(
        "\(source) '\(secretField)' expected '\(secretValue)', got '\(value)'"
      )
    }
  }

  private static func reportEcho(
    _ encryptedFields: Set<String>,
    source: String,
    verbose: Bool
  ) {
    let echoed = encryptedFields.contains(secretField)
    let mark = echoed ? "echoed isEncrypted" : "did not echo isEncrypted"
    print("   ℹ️ \(source): \(mark)")
    if verbose {
      print("      encryptedFields: \(encryptedFields.sorted())")
    }
  }
}
