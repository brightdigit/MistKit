//
//  StringListRoundTripPhase.swift
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

/// Live-verifies `Note.tags` (`LIST<STRING>`) round-trips through create + lookup
/// using the homogeneous ``FieldValue/Arity`` API (issue #481).
///
/// Writes one record with a non-empty string list and one with an empty list,
/// looks both up, and asserts the domain values come back as
/// `.string(.list(...))`. Appends the new record names so ``CleanupPhase``
/// deletes them.
internal struct StringListRoundTripPhase: IntegrationPhase {
  internal typealias Input = CreatedRecordNames
  internal typealias Output = CreatedRecordNames

  internal static let title = "String list (tags) round-trip"
  internal static let emoji = "🏷️"
  internal static let apiName = "createRecord+lookupRecords"

  private static let populatedTags = ["a", "b"]
  private static let emptyTags: [String] = []

  internal func run(
    input: CreatedRecordNames,
    context: PhaseContext
  ) async throws -> CreatedRecordNames {
    print("\n\(Self.emoji) \(Self.title)")

    let populatedName = "mistkit-tags-\(UUID().uuidString.lowercased())"
    let emptyName = "mistkit-tags-empty-\(UUID().uuidString.lowercased())"

    _ = try await context.service.createRecord(
      recordType: MistDemoConfig.recordType,
      recordName: populatedName,
      fields: [
        "title": .string(.value("Tags populated")),
        "tags": .string(.list(Self.populatedTags)),
      ],
      database: context.database
    )
    _ = try await context.service.createRecord(
      recordType: MistDemoConfig.recordType,
      recordName: emptyName,
      fields: [
        "title": .string(.value("Tags empty")),
        "tags": .string(.list(Self.emptyTags)),
      ],
      database: context.database
    )

    if context.verbose {
      print("   ✅ Created: \(populatedName) tags=\(Self.populatedTags)")
      print("   ✅ Created: \(emptyName) tags=[]")
    }

    let results = try await context.service.lookupRecords(
      recordNames: [populatedName, emptyName],
      database: context.database
    )
    let recordsByName = Dictionary(
      uniqueKeysWithValues: results.compactMap { result -> (String, RecordInfo)? in
        guard case .success(let record) = result else { return nil }
        return (record.recordName, record)
      }
    )

    try Self.verifyTags(
      in: recordsByName[populatedName],
      recordName: populatedName,
      expected: Self.populatedTags
    )
    try Self.verifyTags(
      in: recordsByName[emptyName],
      recordName: emptyName,
      expected: Self.emptyTags
    )

    print("✅ String list tags round-trip verified (populated + empty)")

    return CreatedRecordNames(input.names + [populatedName, emptyName])
  }

  private static func verifyTags(
    in record: RecordInfo?,
    recordName: String,
    expected: [String]
  ) throws {
    guard let record else {
      throw IntegrationTestError.verificationFailed(
        "Lookup of '\(recordName)' did not return a record for tags round-trip"
      )
    }
    guard let tags = record.fields["tags"]?.stringListValue else {
      throw IntegrationTestError.verificationFailed(
        """
        Record \(record.recordName) tags did not round-trip as .string(.list); \
        got \(String(describing: record.fields["tags"]))
        """
      )
    }
    guard tags == expected else {
      throw IntegrationTestError.verificationFailed(
        """
        Record \(record.recordName) tags mismatch: \
        expected \(expected), got \(tags)
        """
      )
    }
  }
}
