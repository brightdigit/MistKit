//
//  CSVFormatterTests+RecordInfo.swift
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

internal import Foundation
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension CSVFormatterTests {
  @Suite("RecordInfo")
  internal struct RecordInfoFormat {
    @Test("Format basic RecordInfo with CSV headers")
    internal func formatBasicRecord() throws {
      let record = RecordInfo(
        recordName: "record-001",
        recordType: "TodoItem",
        recordChangeTag: "tag123",
        fields: [:]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      #expect(output.hasPrefix("Field,Value\n"))
      #expect(output.contains("recordName,record-001"))
      #expect(output.contains("recordType,TodoItem"))
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
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("Field,Value\n"))
      #expect(output.contains("status,"))
      #expect(output.contains("title,"))
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
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("price,"))
      #expect(output.contains("quantity,"))
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
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      let lines = output.components(separatedBy: "\n")
      // Skip header, recordName, recordType
      let fieldLines = lines.dropFirst(3).filter { !$0.isEmpty }

      // Fields should be sorted alphabetically
      let fieldNames = fieldLines.compactMap { line -> String? in
        line.components(separatedBy: ",").first
      }

      #expect(fieldNames.contains("apple"))
      #expect(fieldNames.contains("middle"))
      #expect(fieldNames.contains("zebra"))

      // Verify order
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
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      #expect(output.hasPrefix("Field,Value\n"))
      #expect(output.contains("recordName,empty-001"))
      #expect(output.contains("recordType,Empty"))

      // Should only have header + 2 lines (recordName, recordType)
      let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
      #expect(lines.count == 3)
    }
  }
}
