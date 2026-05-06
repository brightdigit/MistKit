//
//  YAMLFormatterTests+YAMLEscaping.swift
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
  // swiftlint:disable type_body_length
  @Suite("YAML Escaping")
  internal struct YAMLEscaping {
    @Test("Format RecordInfo with colon in value")
    internal func formatRecordWithColonInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Colon",
        fields: [
          "content": .string("Key: Value")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Value with colon should be quoted
      #expect(output.contains("  content: \"Key: Value\""))
    }

    @Test("Format RecordInfo with hash in value")
    internal func formatRecordWithHashInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Hash",
        fields: [
          "tag": .string("#important")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Value starting with # should be quoted
      #expect(output.contains("  tag: \"#important\""))
    }

    @Test("Format RecordInfo with quotes in value")
    internal func formatRecordWithQuotesInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Quote",
        fields: [
          "text": .string("He said \"hello\"")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Quotes should be escaped with backslash
      #expect(output.contains("\\\""))
    }

    @Test("Format RecordInfo with newline in value")
    internal func formatRecordWithNewlineInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Text",
        fields: [
          "content": .string("Line one\nLine two")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Multiline string should use block scalar
      #expect(output.contains("  content: |"))
    }

    @Test("Format RecordInfo with backslash in value")
    internal func formatRecordWithBackslashInValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Path",
        fields: [
          "path": .string("C:\\Users\\test")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Backslashes should be escaped
      #expect(output.contains("\\\\"))
    }

    @Test("Format RecordInfo with YAML boolean keywords")
    internal func formatRecordWithBooleanKeywords() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Keywords",
        fields: [
          "yes_field": .string("yes"),
          "no_field": .string("no"),
          "true_field": .string("true"),
          "false_field": .string("false"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // YAML boolean keywords should be quoted
      #expect(output.contains("\"yes\""))
      #expect(output.contains("\"no\""))
      #expect(output.contains("\"true\""))
      #expect(output.contains("\"false\""))
    }

    @Test("Format RecordInfo with numeric string")
    internal func formatRecordWithNumericString() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Numeric",
        fields: [
          "code": .string("12345"),
          "decimal": .string("3.14"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Numeric strings should be quoted to preserve as strings
      #expect(output.contains("\"12345\""))
      #expect(output.contains("\"3.14\""))
    }

    @Test("Format RecordInfo with empty string value")
    internal func formatRecordWithEmptyStringValue() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Empty",
        fields: [
          "empty": .string("")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Empty string should be quoted
      #expect(output.contains("  empty: \"\""))
    }

    @Test("Format RecordInfo with leading whitespace")
    internal func formatRecordWithLeadingWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Whitespace",
        fields: [
          "text": .string("  leading spaces")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Leading whitespace should cause quoting
      #expect(output.contains("\"  leading spaces\""))
    }

    @Test("Format RecordInfo with trailing whitespace")
    internal func formatRecordWithTrailingWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Whitespace",
        fields: [
          "text": .string("trailing spaces  ")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Trailing whitespace should cause quoting
      #expect(output.contains("\"trailing spaces  \""))
    }

    @Test("Format RecordInfo with special YAML characters")
    internal func formatRecordWithSpecialYAMLChars() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Special",
        fields: [
          "brackets": .string("[array]"),
          "braces": .string("{object}"),
          "ampersand": .string("&reference"),
          "asterisk": .string("*alias"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Special YAML characters should be quoted
      #expect(output.contains("\"[array]\""))
      #expect(output.contains("\"{object}\""))
      #expect(output.contains("\"&reference\""))
      #expect(output.contains("\"*alias\""))
    }

    @Test("Format RecordInfo with tab character")
    internal func formatRecordWithTabCharacter() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Tab",
        fields: [
          "content": .string("Column1\tColumn2")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Tab should be escaped
      #expect(output.contains("\\t"))
    }

    @Test("Format RecordInfo with carriage return")
    internal func formatRecordWithCarriageReturn() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "CR",
        fields: [
          "content": .string("Line1\rLine2")
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Carriage return should be escaped
      #expect(output.contains("\\r"))
    }

    @Test("Format RecordInfo with null keyword")
    internal func formatRecordWithNullKeyword() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Null",
        fields: [
          "value": .string("null"),
          "tilde": .string("~"),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // YAML null keywords should be quoted
      #expect(output.contains("\"null\""))
      #expect(output.contains("\"~\""))
    }
  }
  // swiftlint:enable type_body_length
}
