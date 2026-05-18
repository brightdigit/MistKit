//
//  YAMLFormatterTests+YAMLEscaping+ReservedStrings.swift
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

extension YAMLFormatterTests.YAMLEscaping {
  @Suite("YAML Escaping — Reserved Strings")
  internal struct ReservedStrings {
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
}
