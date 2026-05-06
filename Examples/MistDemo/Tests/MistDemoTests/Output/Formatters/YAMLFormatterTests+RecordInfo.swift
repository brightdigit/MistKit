//
//  YAMLFormatterTests+RecordInfo.swift
//  MistDemoTests
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
import MistKit
import Testing

@testable import MistDemoKit

extension YAMLFormatterTests {
  @Suite("RecordInfo")
  internal struct RecordInfoFormat {
    @Test("Format basic RecordInfo with YAML structure")
    internal func formatBasicRecord() throws {
      let record = RecordInfo(
        recordName: "record-001",
        recordType: "TodoItem",
        recordChangeTag: "tag123",
        fields: [:]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("recordName: record-001"))
      #expect(output.contains("recordType: TodoItem"))
    }

    @Test("Format RecordInfo with string fields")
    internal func formatRecordWithStringFields() throws {
      let record = RecordInfo(
        recordName: "task-001",
        recordType: "Task",
        fields: [
          "title": .string("Buy groceries"),
          "status": .string("pending"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("recordName: task-001"))
      #expect(output.contains("recordType: Task"))
      #expect(output.contains("fields:"))
      #expect(output.contains("  title: Buy groceries"))
      #expect(output.contains("  status: pending"))
    }

    @Test("Format RecordInfo with numeric fields")
    internal func formatRecordWithNumericFields() throws {
      let record = RecordInfo(
        recordName: "item-001",
        recordType: "Product",
        fields: [
          "price": .double(19.99),
          "quantity": .int64(42),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("  price:"))
      #expect(output.contains("  quantity:"))
    }

    @Test("Format RecordInfo with sorted field names")
    internal func formatRecordWithSortedFields() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Item",
        fields: [
          "zebra": .string("last"),
          "apple": .string("first"),
          "middle": .string("between"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      let lines = output.components(separatedBy: "\n")
      let fieldLines = lines.filter { $0.hasPrefix("  ") && $0.contains(":") }

      // Extract field names
      let fieldNames = fieldLines.compactMap { line -> String? in
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return trimmed.components(separatedBy: ":").first
      }

      #expect(fieldNames.contains("apple"))
      #expect(fieldNames.contains("middle"))
      #expect(fieldNames.contains("zebra"))

      // Verify alphabetical order
      if let appleIndex = fieldNames.firstIndex(of: "apple"),
        let middleIndex = fieldNames.firstIndex(of: "middle"),
        let zebraIndex = fieldNames.firstIndex(of: "zebra")
      {
        #expect(appleIndex < middleIndex)
        #expect(middleIndex < zebraIndex)
      }
    }

    @Test("Format RecordInfo with empty fields")
    internal func formatRecordWithEmptyFields() throws {
      let record = RecordInfo(
        recordName: "empty-001",
        recordType: "Empty",
        fields: [:]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("recordName: empty-001"))
      #expect(output.contains("recordType: Empty"))
      #expect(!output.contains("fields:"))
    }

    @Test("Format RecordInfo with field indentation")
    internal func formatRecordWithFieldIndentation() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Test",
        fields: [
          "field1": .string("value1")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Fields should be indented with 2 spaces
      #expect(output.contains("fields:\n"))
      #expect(output.contains("  field1: value1"))
    }
  }
}
