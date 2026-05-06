//
//  CSVFormatterTests+CSVEscaping.swift
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

extension CSVFormatterTests {
  @Suite("CSV Escaping")
  internal struct CSVEscaping {
    @Test("Format RecordInfo with comma in field value")
    internal func formatRecordWithCommaInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Note",
        fields: [
          "description": .string("Item one, item two, item three")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Value with comma should be quoted per RFC 4180
      #expect(output.contains("\"Item one, item two, item three\""))
    }

    @Test("Format RecordInfo with quote in field value")
    internal func formatRecordWithQuoteInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Quote",
        fields: [
          "text": .string("He said \"hello\" to me")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Quotes should be escaped by doubling them
      #expect(output.contains("\"He said \"\"hello\"\" to me\""))
    }

    @Test("Format RecordInfo with newline in field value")
    internal func formatRecordWithNewlineInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Text",
        fields: [
          "content": .string("Line one\nLine two")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Newline should cause quoting
      #expect(output.contains("\"Line one\nLine two\""))
    }

    @Test("Format RecordInfo with tab in field value")
    internal func formatRecordWithTabInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Data",
        fields: [
          "content": .string("Column1\tColumn2")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Tab should cause quoting
      #expect(output.contains("\"Column1\tColumn2\""))
    }

    @Test("Format RecordInfo with multiple special characters")
    internal func formatRecordWithMultipleSpecialChars() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Complex",
        fields: [
          "data": .string("Value with \"quotes\", commas, and\nnewlines")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Should properly escape all special characters
      #expect(output.contains("\"Value with \"\"quotes\"\", commas, and\nnewlines\""))
    }

    @Test("Format RecordInfo with simple value requiring no escaping")
    internal func formatRecordWithSimpleValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Simple",
        fields: [
          "title": .string("SimpleValue")
        ]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      // Simple value should not be quoted
      #expect(output.contains("title,SimpleValue"))
      #expect(!output.contains("\"SimpleValue\""))
    }

    @Test("Format RecordInfo name with special characters")
    internal func formatRecordNameWithSpecialChars() throws {
      let record = RecordInfo(
        recordName: "record,with,commas",
        recordType: "Type\"with\"quotes",
        fields: [:]
      )
      let formatter = CSVFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("\"record,with,commas\""))
      #expect(output.contains("\"Type\"\"with\"\"quotes\""))
    }
  }
}
