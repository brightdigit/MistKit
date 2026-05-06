// swiftlint:disable file_length
//
//  TableFormatterTests+EdgeCases.swift
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

extension TableFormatterTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("Format empty string values")
    internal func formatEmptyStringValues() throws {
      let record = RecordInfo(
        recordName: "",
        recordType: "",
        fields: [
          "empty": .string("")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Empty strings should still produce valid table output
      #expect(output.contains("Record Name:"))
      #expect(output.contains("Record Type:"))
    }

    @Test("Format with complex field types")
    internal func formatWithComplexFieldTypes() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Complex",
        fields: [
          "reference": .reference(.init(recordName: "ref-001")),
          "location": .location(.init(latitude: 37.7749, longitude: -122.4194)),
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Complex types should be converted to string representation
      #expect(output.contains("location:"))
      #expect(output.contains("reference:"))
    }

    @Test("Table output line structure")
    internal func verifyTableStructure() throws {
      let record = RecordInfo(
        recordName: "verify-001",
        recordType: "Verify",
        fields: [
          "field1": .string("value1"),
          "field2": .string("value2"),
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

      // Verify structure
      #expect(lines.count >= 4)  // Record Name + Record Type + Fields header + at least 2 fields
      #expect(lines[0].hasPrefix("Record Name:"))
      #expect(lines[1].hasPrefix("Record Type:"))
      #expect(lines[2] == "Fields:")
    }

    @Test("Format fallback to JSON for unknown type")
    internal func formatUnknownType() throws {
      struct UnknownType: Encodable {
        let data: String
      }

      let unknown = UnknownType(data: "test")
      let formatter = TableFormatter()

      let output = try formatter.format(unknown)

      // Should fall back to pretty JSON format
      #expect(output.contains("data"))
      #expect(output.contains("test"))
      #expect(output.contains("\n"))  // Pretty printed JSON has newlines
    }

    @Test("Format RecordInfo with list field")
    internal func formatRecordWithListField() throws {
      let record = RecordInfo(
        recordName: "list-001",
        recordType: "List",
        fields: [
          "tags": .list([.string("tag1"), .string("tag2"), .string("tag3")])
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      #expect(output.contains("tags:"))
    }

    @Test("Whitespace trimming verification")
    internal func verifyWhitespaceTrimming() throws {
      let record = RecordInfo(
        recordName: "trim-test",
        recordType: "Trim",
        fields: [
          "text1": .string("   leading"),
          "text2": .string("trailing   "),
          "text3": .string("   both   "),
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Values should be trimmed
      #expect(output.contains("text1: leading"))
      #expect(output.contains("text2: trailing"))
      #expect(output.contains("text3: both"))
    }

    @Test("Single-line conversion with consecutive whitespace")
    internal func formatConsecutiveWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Whitespace",
        fields: [
          "content": .string("Multiple\n\n\nnewlines and\t\t\ttabs")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Multiple consecutive whitespace chars should each be converted
      #expect(output.contains("content: Multiple"))
    }

    @Test("Format record with only whitespace values")
    internal func formatRecordWithOnlyWhitespace() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Whitespace",
        fields: [
          "spaces": .string("     "),
          "tabs": .string("\t\t\t"),
          "newlines": .string("\n\n\n"),
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // All whitespace values should be trimmed to empty
      // But field names should still appear
      #expect(output.contains("spaces:"))
      #expect(output.contains("tabs:"))
      #expect(output.contains("newlines:"))
    }

    @Test("Format UserInfo with whitespace in email")
    internal func formatUserWithWhitespaceInEmail() throws {
      let user = UserInfo.test(
        userRecordName: "user-005",
        emailAddress: "test\n@example.com"
      )
      let formatter = TableFormatter()

      let output = try formatter.format(user)

      #expect(output.contains("Email: test @example.com"))
    }

    @Test("Readable table format verification")
    internal func verifyReadableFormat() throws {
      let record = RecordInfo(
        recordName: "readable-001",
        recordType: "ReadableTest",
        fields: [
          "field": .string("value")
        ]
      )
      let formatter = TableFormatter()

      let output = try formatter.format(record)

      // Output should be human-readable with proper labels
      #expect(output.contains("Record Name:"))
      #expect(output.contains("Record Type:"))
      #expect(output.contains("Fields:"))

      // Each line should end with a newline
      let lines = output.components(separatedBy: "\n")
      #expect(lines.count > 1)
    }
  }
}
