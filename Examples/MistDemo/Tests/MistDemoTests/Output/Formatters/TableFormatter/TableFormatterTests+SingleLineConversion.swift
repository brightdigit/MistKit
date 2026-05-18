//
//  TableFormatterTests+SingleLineConversion.swift
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

extension TableFormatterTests {
  @Suite("Single-line Conversion")
  internal struct SingleLineConversion {
    @Test("Format RecordInfo with newline in field value")
    internal func formatRecordWithNewlineInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Text",
        fields: [
          "content": .string("Line one\nLine two\nLine three")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Newlines should be converted to spaces for single-line display
      #expect(output.contains("content: Line one Line two Line three"))
      #expect(!output.contains("Line one\nLine two"))
    }

    @Test("Format RecordInfo with carriage return in value")
    internal func formatRecordWithCarriageReturnInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Text",
        fields: [
          "content": .string("Line one\rLine two")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Carriage returns should be converted to spaces
      #expect(output.contains("content: Line one Line two"))
    }

    @Test("Format RecordInfo with tab in field value")
    internal func formatRecordWithTabInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Data",
        fields: [
          "content": .string("Column1\tColumn2\tColumn3")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Tabs should be converted to spaces
      #expect(output.contains("content: Column1 Column2 Column3"))
    }

    @Test("Format RecordInfo with mixed whitespace")
    internal func formatRecordWithMixedWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Mixed",
        fields: [
          "content": .string("Text\n\twith\r\nmixed\twhitespace")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Each whitespace char is converted to a single space (consecutive → multiple spaces)
      #expect(output.contains("content: Text"))
    }

    @Test("Format RecordInfo with leading and trailing whitespace")
    internal func formatRecordWithLeadingTrailingWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Trim",
        fields: [
          "content": .string("  \n\tvalue with spaces\t\n  ")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Leading and trailing whitespace should be trimmed
      #expect(output.contains("content: value with spaces"))
      #expect(!output.contains("content:  "))
      #expect(!output.contains("  value"))
    }

    @Test("Format record name with special characters")
    internal func formatRecordNameWithSpecialChars() throws {
      let record = RecordInfo(
        recordName: "record\nwith\nnewlines",
        recordType: "Type\twith\ttabs",
        fields: [:]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Record name and type should have whitespace converted to spaces
      #expect(output.contains("Record Name: record with newlines"))
      #expect(output.contains("Record Type: Type with tabs"))
    }
  }
}
