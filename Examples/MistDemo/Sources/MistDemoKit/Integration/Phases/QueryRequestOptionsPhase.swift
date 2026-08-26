//
//  QueryRequestOptionsPhase.swift
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

/// Exercises the `records/query` request options added in #383
/// (`desiredKeys`, `zoneWide`, `numbersAsStrings`) against the live records
/// created earlier in the pipeline.
///
/// `desiredKeys` is the one option whose effect is directly observable at the
/// domain layer — CloudKit omits every non-requested field — so this phase
/// asserts that our returned records carry `title` but *not* `index`. The other
/// two options are wire-level hints CloudKit does not echo back in a
/// distinguishable domain form, so they are exercised (the request must
/// succeed) but not asserted.
internal struct QueryRequestOptionsPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Query with request options (desiredKeys/zoneWide)"
  internal static let emoji = "🎛️ "
  internal static let apiName = "queryRecords"

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji)\(Self.title)")

    do {
      let result = try await context.service.queryRecords(
        Query(recordType: MistDemoConfig.recordType),
        desiredKeys: ["title"],
        zoneWide: true,
        numbersAsStrings: true,
        database: context.database
      )
      print("✅ Queried \(result.records.count) record(s) with request options")

      let ours = result.records.filter { input.names.contains($0.recordName) }
      guard let sample = ours.first else {
        print("   ⚠️  None of our test records came back — skipping desiredKeys assertion")
        return NoState()
      }

      // desiredKeys: ["title"] must exclude the "index" field we wrote at create.
      let unexpected = sample.fields.keys.filter { $0 != "title" }
      guard unexpected.isEmpty else {
        throw IntegrationTestError.verificationFailed(
          "desiredKeys was ignored — query returned unrequested field(s): "
            + unexpected.sorted().joined(separator: ", ")
        )
      }
      print("   ✅ desiredKeys honored: only \(sample.fields.keys.sorted()) returned")
    } catch {
      // Schema propagation in development can lag behind the first write, so a
      // freshly-created record type may still 404. LookupRecordsPhase already
      // proves the records exist by name; treat the lag as non-fatal here.
      guard case CloudKitError.notFound = error else {
        throw error
      }
      print("⚠️  queryRecords returned NOT_FOUND — schema may not be indexed yet (non-fatal)")
    }

    return NoState()
  }
}
