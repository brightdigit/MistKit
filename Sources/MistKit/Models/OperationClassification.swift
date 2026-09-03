//
//  OperationClassification.swift
//  MistKit
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

/// Classifies CloudKit record operations as creates or updates.
///
/// CloudKit's `/records/modify` endpoint does not indicate in its response
/// whether each operation resulted in a newly-created record or an update to
/// an existing one. The proven workaround is to query the existing record
/// names for a record type before issuing the modify, then partition each
/// proposed operation by whether its record name was already present.
///
/// `OperationClassification` captures the result of that partitioning so that
/// `CloudKitService.modifyRecords(_:classification:atomic:)` can attribute
/// each returned `RecordInfo` to a create or an update.
///
/// ## Example
/// ```swift
/// let existing = try await service.fetchExistingRecordNames(recordType: "Article")
/// let classification = OperationClassification(
///   operations: operations,
///   existingRecordNames: existing
/// )
/// let result = try await service.modifyRecords(
///   operations,
///   classification: classification
/// )
/// print("Created: \(result.createdCount), Updated: \(result.updatedCount)")
/// ```
public struct OperationClassification: Sendable, Equatable {
  /// Record names that are expected to be created (not present in CloudKit).
  public let creates: Set<RecordName>

  /// Record names that are expected to be updated (already present in CloudKit).
  public let updates: Set<RecordName>

  /// Build a classification by comparing proposed record names against existing ones.
  ///
  /// Operations whose record name is in `existingRecordNames` are classified as
  /// updates; the rest are classified as creates. Duplicate names in
  /// `proposedRecordNames` are folded into the same set entry.
  ///
  /// - Parameters:
  ///   - proposedRecordNames: Record names that will be sent to CloudKit.
  ///   - existingRecordNames: Record names already present in CloudKit
  ///     (typically obtained via `fetchExistingRecordNames(recordType:)`).
  public init(
    proposedRecordNames: [RecordName],
    existingRecordNames: Set<RecordName>
  ) {
    var creates = Set<RecordName>()
    var updates = Set<RecordName>()

    for recordName in proposedRecordNames {
      if existingRecordNames.contains(recordName) {
        updates.insert(recordName)
      } else {
        creates.insert(recordName)
      }
    }

    self.creates = creates
    self.updates = updates
  }

  /// Build a classification directly from a sequence of `RecordOperation` values.
  ///
  /// Operations without a `recordName` (anonymous creates where CloudKit will
  /// assign the name) are skipped — they cannot be matched against existing
  /// names by definition.
  ///
  /// - Parameters:
  ///   - operations: The record operations that will be sent to CloudKit.
  ///   - existingRecordNames: Record names already present in CloudKit.
  public init(
    operations: [RecordOperation],
    existingRecordNames: Set<RecordName>
  ) {
    let proposedNames = operations.compactMap(\.recordName)
    self.init(
      proposedRecordNames: proposedNames,
      existingRecordNames: existingRecordNames
    )
  }

  /// Direct initializer for tests and manual construction.
  ///
  /// Prefer the comparison-based initializers in production code.
  internal init(creates: Set<RecordName>, updates: Set<RecordName>) {
    self.creates = creates
    self.updates = updates
  }
}
