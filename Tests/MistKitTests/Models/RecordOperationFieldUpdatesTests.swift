//
//  RecordOperationFieldUpdatesTests.swift
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

import Testing

@testable import MistKit

@Suite("RecordOperation(fieldUpdates:)")
internal struct RecordOperationFieldUpdatesTests {
  @Test("non-nil values become fields and nil values become cleared fields")
  internal func splitsValuesAndClears() {
    let operation = RecordOperation(
      operationType: .update,
      recordType: "Note",
      recordName: "n-1",
      fieldUpdates: ["title": .string(.value("Hi")), "body": nil],
      recordChangeTag: "tag-1"
    )
    #expect(operation.operationType == .update)
    #expect(operation.recordName == "n-1")
    #expect(operation.fields == ["title": .string(.value("Hi"))])
    #expect(operation.clearedFields == ["body"])
    #expect(operation.recordChangeTag == "tag-1")
  }

  @Test("empty updates write and clear nothing")
  internal func emptyUpdates() {
    let operation = RecordOperation(
      operationType: .delete,
      recordType: "Note",
      recordName: "n-1",
      fieldUpdates: [:]
    )
    #expect(operation.fields.isEmpty)
    #expect(operation.clearedFields.isEmpty)
    #expect(operation.recordChangeTag == nil)
  }

  @Test("encrypted field names pass through")
  internal func encryptedFieldsPassThrough() {
    let operation = RecordOperation(
      operationType: .create,
      recordType: "Note",
      recordName: nil,
      fieldUpdates: ["secret": .string(.value("x"))],
      encryptedFields: ["secret"]
    )
    #expect(operation.recordName == nil)
    #expect(operation.encryptedFields == ["secret"])
  }
}
