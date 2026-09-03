//
//  ModifyRequestOptionsPhase.swift
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

/// Exercises the `records/modify` request options added in #384
/// (`zoneID`, `desiredKeys`, `numbersAsStrings`).
///
/// A `forceUpdate` merges the provided fields without dropping the others, so
/// the record keeps its `index` field server-side. Requesting
/// `desiredKeys: ["title"]` must therefore return the updated record with
/// `title` only and *no* `index` — that omission is the assertion. `zoneID`
/// (default zone) and `numbersAsStrings` are exercised alongside but not
/// asserted, since CloudKit does not echo them in a distinguishable domain
/// form.
internal struct ModifyRequestOptionsPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Modify with request options (zoneID/desiredKeys)"
  internal static let emoji = "🎛️ "
  internal static let apiName = "modifyRecords"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji)\(Self.title)")

    guard let recordName = input.names.first else {
      print("   ⚠️  No test records available — skipping")
      return NoState()
    }

    let operation = RecordOperation(
      operationType: .forceUpdate,
      recordType: MistDemoConfig.recordType,
      recordName: RecordName(recordName),
      fields: ["title": .string("Request-options update")]
    )

    let results = try await context.service.modifyRecords(
      [operation],
      zoneID: .defaultZone,
      desiredKeys: ["title"],
      numbersAsStrings: true,
      database: context.database
    )

    guard case .success(let record) = results.first else {
      throw IntegrationTestError.verificationFailed(
        "modifyRecords with request options returned no successful result"
      )
    }
    print("✅ Modified \(record.recordName) with request options")

    // desiredKeys: ["title"] must exclude the "index" field the record still
    // carries after a merge-style forceUpdate.
    let unexpected = record.fields.keys.filter { $0 != "title" }
    guard unexpected.isEmpty else {
      throw IntegrationTestError.verificationFailed(
        "desiredKeys was ignored — modify response returned unrequested field(s): "
          + unexpected.sorted().joined(separator: ", ")
      )
    }
    print("   ✅ desiredKeys honored: only \(record.fields.keys.sorted()) returned")

    return NoState()
  }
}
