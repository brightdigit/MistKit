//
//  BatchSyncResultTests.swift
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
import Testing

@testable import MistKit

@Suite("BatchSyncResult")
internal struct BatchSyncResultTests {
  // MARK: - Helpers

  internal static func makeRecord(
    name: String,
    type: String = "Article"
  ) -> RecordInfo {
    RecordInfo(
      recordName: name,
      recordType: type,
      recordChangeTag: nil,
      fields: [:]
    )
  }

  /// Builds an error `RecordInfo` via the same response-decoding path used in
  /// production (`RecordInfo.init(from:)` with an empty `RecordResponse`),
  /// rather than hardcoding the "Unknown" sentinel string in the test.
  /// This matches the pattern in `RecordInfoTests.recordInfoWithUnknownRecord`.
  internal static func makeErrorRecord() -> RecordInfo {
    RecordInfo(from: Components.Schemas.RecordResponse())
  }

  // MARK: - Tests

  @Test("partitions records into created, updated, failed, and unclassified")
  internal func partitionsRecordsIntoAllFourCategories() {
    let classification = OperationClassification(
      creates: ["new-1", "new-2"],
      updates: ["existing-1"]
    )
    let records: [RecordInfo] = [
      Self.makeRecord(name: "new-1"),
      Self.makeRecord(name: "existing-1"),
      Self.makeRecord(name: "new-2"),
      Self.makeRecord(name: "server-assigned-name"),
      Self.makeErrorRecord(),
    ]

    let result = BatchSyncResult(records: records, classification: classification)

    #expect(result.createdCount == 2)
    #expect(result.updatedCount == 1)
    #expect(result.failedCount == 1)
    #expect(result.unclassifiedCount == 1)
    #expect(result.created.map(\.recordName).sorted() == ["new-1", "new-2"])
    #expect(result.updated.map(\.recordName) == ["existing-1"])
    #expect(result.unclassified.map(\.recordName) == ["server-assigned-name"])
  }

  @Test("counts add up across all categories")
  internal func countsAddUpAcrossCategories() {
    let classification = OperationClassification(
      creates: ["a"],
      updates: ["b"]
    )
    let records: [RecordInfo] = [
      Self.makeRecord(name: "a"),
      Self.makeRecord(name: "b"),
      Self.makeRecord(name: "c"),
      Self.makeErrorRecord(),
    ]

    let result = BatchSyncResult(records: records, classification: classification)

    #expect(result.totalCount == 4)
    #expect(result.succeededCount == 3)
    #expect(result.totalCount == result.createdCount + result.updatedCount
      + result.failedCount + result.unclassifiedCount)
  }

  @Test("treats error records as failures regardless of classification")
  internal func treatsErrorRecordsAsFailures() {
    // Build a classification that *would* claim the error record as a create
    // by reading its actual recordName, then verify the failure check wins.
    let errorRecord = Self.makeErrorRecord()
    let classification = OperationClassification(
      creates: [errorRecord.recordName],
      updates: []
    )

    let result = BatchSyncResult(
      records: [errorRecord],
      classification: classification
    )

    #expect(result.failedCount == 1)
    #expect(result.createdCount == 0)
  }

  @Test("returns empty buckets for empty inputs")
  internal func returnsEmptyBucketsForEmptyInputs() {
    let classification = OperationClassification(creates: [], updates: [])
    let result = BatchSyncResult(records: [], classification: classification)

    #expect(result.totalCount == 0)
    #expect(result.succeededCount == 0)
    #expect(result.created.isEmpty)
    #expect(result.updated.isEmpty)
    #expect(result.failed.isEmpty)
    #expect(result.unclassified.isEmpty)
  }

  @Test("manual init exposes the supplied arrays directly")
  internal func manualInitExposesSuppliedArrays() {
    let result = BatchSyncResult(
      created: [Self.makeRecord(name: "a")],
      updated: [Self.makeRecord(name: "b"), Self.makeRecord(name: "c")],
      failed: [Self.makeErrorRecord()]
    )

    #expect(result.createdCount == 1)
    #expect(result.updatedCount == 2)
    #expect(result.failedCount == 1)
    #expect(result.unclassifiedCount == 0)
    #expect(result.totalCount == 4)
    #expect(result.succeededCount == 3)
  }
}
