//
//  BatchSyncResult.swift
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

import Foundation

/// Categorized result of a tracked `modifyRecords(_:classification:atomic:)` call.
///
/// Returned by `CloudKitService.modifyRecords(_:classification:atomic:)`,
/// this struct partitions the records returned by CloudKit into four groups
/// based on the supplied `OperationClassification`:
///
/// - `created`: results whose record name was classified as a create
/// - `updated`: results whose record name was classified as an update
/// - `failed`: results that came back as errors (`RecordInfo.isError == true`)
/// - `unclassified`: successful results whose record name was in neither
///   the creates nor updates sets — for example, anonymous creates where
///   CloudKit assigned the record name server-side, or records whose name
///   was not included in the classification
///
/// Use the `*Count` properties to drive sync summaries and audit logs.
public struct BatchSyncResult: Sendable {
  /// Records classified as newly created.
  public let created: [RecordInfo]

  /// Records classified as updates to existing records.
  public let updated: [RecordInfo]

  /// Records that came back as errors.
  public let failed: [RecordInfo]

  /// Successful records that could not be classified as either a create or update.
  ///
  /// Typically contains anonymous creates where CloudKit assigned the record
  /// name server-side, since their names won't appear in either set of the
  /// supplied `OperationClassification`.
  public let unclassified: [RecordInfo]

  /// Number of records classified as created.
  public var createdCount: Int { created.count }

  /// Number of records classified as updated.
  public var updatedCount: Int { updated.count }

  /// Number of records that returned an error.
  public var failedCount: Int { failed.count }

  /// Number of successful records that could not be classified.
  public var unclassifiedCount: Int { unclassified.count }

  /// Total number of records returned by CloudKit, across all categories.
  public var totalCount: Int {
    created.count + updated.count + failed.count + unclassified.count
  }

  /// Number of records that completed successfully (created + updated + unclassified).
  public var succeededCount: Int {
    created.count + updated.count + unclassified.count
  }

  /// Build a `BatchSyncResult` directly from category arrays.
  ///
  /// Prefer `init(records:classification:)` in production code; this
  /// initializer is intended for tests and manual construction.
  public init(
    created: [RecordInfo],
    updated: [RecordInfo],
    failed: [RecordInfo],
    unclassified: [RecordInfo] = []
  ) {
    self.created = created
    self.updated = updated
    self.failed = failed
    self.unclassified = unclassified
  }

  /// Partition a flat array of `RecordInfo` results into a `BatchSyncResult`
  /// using a pre-computed classification.
  ///
  /// Each record is sorted as follows:
  /// 1. If `record.isError` is `true`, it is added to `failed`.
  /// 2. Else if `record.recordName` is in `classification.creates`, it is added
  ///    to `created`.
  /// 3. Else if `record.recordName` is in `classification.updates`, it is added
  ///    to `updated`.
  /// 4. Otherwise it is added to `unclassified`.
  ///
  /// - Parameters:
  ///   - records: The records returned by `modifyRecords`.
  ///   - classification: The classification used to partition the records.
  public init(
    records: [RecordInfo],
    classification: OperationClassification
  ) {
    var created: [RecordInfo] = []
    var updated: [RecordInfo] = []
    var failed: [RecordInfo] = []
    var unclassified: [RecordInfo] = []

    for record in records {
      if record.isError {
        failed.append(record)
      } else if classification.creates.contains(record.recordName) {
        created.append(record)
      } else if classification.updates.contains(record.recordName) {
        updated.append(record)
      } else {
        unclassified.append(record)
      }
    }

    self.created = created
    self.updated = updated
    self.failed = failed
    self.unclassified = unclassified
  }
}
