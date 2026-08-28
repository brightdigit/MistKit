//
//  LookupRecordsPhase.swift
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

internal struct LookupRecordsPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = NoState

  internal static let title = "Lookup records by name"
  internal static let emoji = "🔍"
  internal static let apiName = "lookupRecords"

  /// Verifies the seeded `timestamp` field comes back as `.date` with its
  /// original value.
  ///
  /// This exercises MistKit's response TIMESTAMP recovery (issue #376)
  /// end-to-end: a whole-millisecond CloudKit timestamp is ambiguous on the
  /// wire and would decode as `.int64` unless the response's `TIMESTAMP` type
  /// tag is honored. Failing loud here catches a regression in that recovery.
  private static func verifyTimestampRoundTrip(in records: [RecordInfo]) throws {
    let expected = CreateRecordsPhase.verificationTimestamp.timeIntervalSince1970
    for record in records where record.fields["timestamp"] != nil {
      guard case .date(let value)? = record.fields["timestamp"] else {
        throw IntegrationTestError.verificationFailed(
          "Record \(record.recordName) timestamp did not round-trip as a date"
        )
      }
      guard value.timeIntervalSince1970 == expected else {
        throw IntegrationTestError.verificationFailed(
          """
          Record \(record.recordName) timestamp mismatch: \
          expected \(expected), got \(value.timeIntervalSince1970)
          """
        )
      }
    }
  }

  internal func run(
    input: CreatedRecordNames, context: PhaseContext
  ) async throws -> NoState {
    print("\n\(Self.emoji) \(Self.title)")

    let lookupNames = Array(input.names.prefix(min(3, input.names.count)))
    if context.verbose {
      print("   Looking up \(lookupNames.count) of \(input.names.count) record(s) by name")
    }

    let results = try await context.service.lookupRecords(
      recordNames: lookupNames,
      database: context.database
    )
    let records = results.compactMap { result in
      if case .success(let record) = result { record } else { nil }
    }

    print("✅ Looked up \(records.count) record(s)")

    try Self.verifyTimestampRoundTrip(in: records)

    if context.verbose {
      for record in records {
        print("   - \(record.recordName)")
      }
    }

    return NoState()
  }
}
