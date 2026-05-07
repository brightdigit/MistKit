//
//  OperationClassificationTests.swift
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

@Suite("OperationClassification")
internal struct OperationClassificationTests {
  @Test("partitions proposed names against existing names")
  internal func partitionsProposedNamesAgainstExistingNames() {
    let classification = OperationClassification(
      proposedRecordNames: ["a", "b", "c", "d"],
      existingRecordNames: ["b", "d", "e"]
    )

    #expect(classification.creates == ["a", "c"])
    #expect(classification.updates == ["b", "d"])
  }

  @Test("classifies all as creates when nothing exists")
  internal func classifiesAllAsCreatesWhenNothingExists() {
    let classification = OperationClassification(
      proposedRecordNames: ["a", "b", "c"],
      existingRecordNames: []
    )

    #expect(classification.creates == ["a", "b", "c"])
    #expect(classification.updates.isEmpty)
  }

  @Test("classifies all as updates when all already exist")
  internal func classifiesAllAsUpdatesWhenAllAlreadyExist() {
    let classification = OperationClassification(
      proposedRecordNames: ["a", "b"],
      existingRecordNames: ["a", "b", "c"]
    )

    #expect(classification.creates.isEmpty)
    #expect(classification.updates == ["a", "b"])
  }

  @Test("collapses duplicate proposed names into a single set entry")
  internal func collapsesDuplicateProposedNames() {
    let classification = OperationClassification(
      proposedRecordNames: ["a", "a", "b", "b", "b"],
      existingRecordNames: ["b"]
    )

    #expect(classification.creates == ["a"])
    #expect(classification.updates == ["b"])
  }

  @Test("returns empty sets for empty inputs")
  internal func returnsEmptySetsForEmptyInputs() {
    let classification = OperationClassification(
      proposedRecordNames: [],
      existingRecordNames: []
    )

    #expect(classification.creates.isEmpty)
    #expect(classification.updates.isEmpty)
  }

  @Test("classifies operations directly via convenience initializer")
  internal func classifiesOperationsDirectly() {
    let operations: [RecordOperation] = [
      .create(recordType: "Article", recordName: "new-1", fields: [:]),
      .update(
        recordType: "Article",
        recordName: "existing-1",
        fields: [:],
        recordChangeTag: nil
      ),
      .create(recordType: "Article", recordName: "new-2", fields: [:]),
    ]

    let classification = OperationClassification(
      operations: operations,
      existingRecordNames: ["existing-1"]
    )

    #expect(classification.creates == ["new-1", "new-2"])
    #expect(classification.updates == ["existing-1"])
  }

  @Test("skips anonymous operations that have no record name")
  internal func skipsAnonymousOperations() {
    let operations: [RecordOperation] = [
      .create(recordType: "Article", recordName: nil, fields: [:]),
      .create(recordType: "Article", recordName: "named", fields: [:]),
    ]

    let classification = OperationClassification(
      operations: operations,
      existingRecordNames: []
    )

    #expect(classification.creates == ["named"])
    #expect(classification.updates.isEmpty)
  }

  @Test("equates classifications with the same contents")
  internal func equatesClassificationsWithSameContents() {
    let lhs = OperationClassification(creates: ["a"], updates: ["b"])
    let rhs = OperationClassification(creates: ["a"], updates: ["b"])

    #expect(lhs == rhs)
  }
}
