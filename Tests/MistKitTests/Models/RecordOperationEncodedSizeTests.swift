//
//  RecordOperationEncodedSizeTests.swift
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

@Suite("RecordOperation.encodedRecordSize()")
internal struct RecordOperationEncodedSizeTests {
  @Test("delete operations report a small envelope-only size")
  internal func deleteReportsSmallSize() throws {
    let operation = RecordOperation.delete(recordType: "Note", recordName: "n-1")
    let size = try operation.encodedRecordSize()
    #expect(size > 0)
    // Envelope only: recordName + recordType + empty fields object.
    #expect(size < 200)
  }

  @Test("create operation reports a non-zero size")
  internal func createReturnsPositive() throws {
    let operation = RecordOperation.create(
      recordType: "Note",
      fields: ["body": .string("hello")]
    )
    #expect(try operation.encodedRecordSize() > 0)
  }

  @Test("size scales with field content length")
  internal func sizeScalesWithContent() throws {
    let small = RecordOperation.create(
      recordType: "Note",
      fields: ["body": .string("x")]
    )
    let large = RecordOperation.create(
      recordType: "Note",
      fields: ["body": .string(String(repeating: "x", count: 10_000))]
    )
    let smallSize = try small.encodedRecordSize()
    let largeSize = try large.encodedRecordSize()
    #expect(largeSize > smallSize)
    // 10_000 chars of "x" plus JSON overhead — must be much larger than the
    // single-char baseline.
    #expect(largeSize - smallSize >= 9_000)
  }

  @Test("size can be compared against CloudKitService.maxRecordDataBytes")
  internal func boundaryComparisonCompiles() throws {
    let operation = RecordOperation.create(
      recordType: "Note",
      fields: ["body": .string("ok")]
    )
    let size = try operation.encodedRecordSize()
    #expect(size <= CloudKitService.maxRecordDataBytes)
  }
}
