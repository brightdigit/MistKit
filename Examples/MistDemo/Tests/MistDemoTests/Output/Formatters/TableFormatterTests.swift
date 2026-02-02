//
//  TableFormatterTests.swift
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

@testable import MistDemo

@Suite("TableFormatter Tests")
struct TableFormatterTests {
  // MARK: - RecordInfo Tests

  @Test("Format basic RecordInfo with table structure")
  func formatBasicRecord() throws {
    let record = RecordInfo(
      recordName: "record-001",
      recordType: "TodoItem",
      recordChangeTag: "tag123",
      fields: [:]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("Record Name: record-001"))
    #expect(output.contains("Record Type: TodoItem"))
  }

  @Test("Format RecordInfo with string fields")
  func formatRecordWithStringFields() throws {
    let record = RecordInfo(
      recordName: "task-001",
      recordType: "Task",
      fields: [
        "title": .string("Buy groceries"),
        "status": .string("pending")
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("Record Name: task-001"))
    #expect(output.contains("Record Type: Task"))
    #expect(output.contains("Fields:"))
    #expect(output.contains("title: Buy groceries"))
    #expect(output.contains("status: pending"))
  }

  @Test("Format RecordInfo with numeric fields")
  func formatRecordWithNumericFields() throws {
    let record = RecordInfo(
      recordName: "item-001",
      recordType: "Product",
      fields: [
        "price": .double(19.99),
        "quantity": .int64(42)
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("price:"))
    #expect(output.contains("quantity:"))
  }

  @Test("Format RecordInfo with sorted field names")
  func formatRecordWithSortedFields() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Item",
      fields: [
        "zebra": .string("last"),
        "apple": .string("first"),
        "middle": .string("between")
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    let lines = output.components(separatedBy: "\n")
    let fieldLines = lines.filter { $0.contains(":") && $0.hasPrefix("  ") }

    // Extract field names (removing leading spaces and trailing colon+value)
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
       let zebraIndex = fieldNames.firstIndex(of: "zebra") {
      #expect(appleIndex < middleIndex)
      #expect(middleIndex < zebraIndex)
    }
  }

  @Test("Format RecordInfo with empty fields")
  func formatRecordWithEmptyFields() throws {
    let record = RecordInfo(
      recordName: "empty-001",
      recordType: "Empty",
      fields: [:]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("Record Name: empty-001"))
    #expect(output.contains("Record Type: Empty"))
    #expect(!output.contains("Fields:"))
  }

  @Test("Format RecordInfo with field indentation")
  func formatRecordWithFieldIndentation() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Test",
      fields: [
        "field1": .string("value1")
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    // Fields should be indented with 2 spaces
    #expect(output.contains("  field1: value1"))
  }

  // MARK: - Single-line Conversion Tests

  @Test("Format RecordInfo with newline in field value")
  func formatRecordWithNewlineInValue() throws {
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
  func formatRecordWithCarriageReturnInValue() throws {
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
  func formatRecordWithTabInValue() throws {
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
  func formatRecordWithMixedWhitespace() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Mixed",
      fields: [
        "content": .string("Text\n\twith\r\nmixed\twhitespace")
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    // All special whitespace should be converted to regular spaces
    #expect(output.contains("content: Text with mixed whitespace"))
  }

  @Test("Format RecordInfo with leading and trailing whitespace")
  func formatRecordWithLeadingTrailingWhitespace() throws {
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
  func formatRecordNameWithSpecialChars() throws {
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

  // MARK: - UserInfo Tests

  @Test("Format basic UserInfo")
  func formatBasicUser() throws {
    let user = UserInfo.test(
      userRecordName: "user-001",
      firstName: "John",
      lastName: "Doe",
      emailAddress: "john.doe@example.com"
    )
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("User Record Name: user-001"))
    #expect(output.contains("First Name: John"))
    #expect(output.contains("Last Name: Doe"))
    #expect(output.contains("Email: john.doe@example.com"))
  }

  @Test("Format UserInfo with minimal fields")
  func formatUserWithMinimalFields() throws {
    let user = UserInfo.test(userRecordName: "user-min")
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("User Record Name: user-min"))
    #expect(!output.contains("First Name:"))
    #expect(!output.contains("Last Name:"))
    #expect(!output.contains("Email:"))
  }

  @Test("Format UserInfo with partial fields")
  func formatUserWithPartialFields() throws {
    let user = UserInfo.test(
      userRecordName: "user-002",
      firstName: "Jane",
      emailAddress: "jane@example.com"
    )
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("User Record Name: user-002"))
    #expect(output.contains("First Name: Jane"))
    #expect(!output.contains("Last Name:"))
    #expect(output.contains("Email: jane@example.com"))
  }

  @Test("Format UserInfo with newlines in fields")
  func formatUserWithNewlinesInFields() throws {
    let user = UserInfo.test(
      userRecordName: "user-003",
      firstName: "John\nJacob",
      lastName: "Smith\nJones"
    )
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    // Newlines should be converted to spaces
    #expect(output.contains("First Name: John Jacob"))
    #expect(output.contains("Last Name: Smith Jones"))
  }

  @Test("Format UserInfo with special characters")
  func formatUserWithSpecialChars() throws {
    let user = UserInfo.test(
      userRecordName: "user-004",
      firstName: "O'Brien",
      lastName: "Müller"
    )
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("First Name: O'Brien"))
    #expect(output.contains("Last Name: Müller"))
  }

  // MARK: - Edge Cases

  @Test("Format empty string values")
  func formatEmptyStringValues() throws {
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
  func formatWithComplexFieldTypes() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Complex",
      fields: [
        "reference": .reference(.init(recordName: "ref-001")),
        "location": .location(.init(latitude: 37.7749, longitude: -122.4194))
      ]
    )
    let formatter = TableFormatter()

    let output = try formatter.format(record)

    // Complex types should be converted to string representation
    #expect(output.contains("location:"))
    #expect(output.contains("reference:"))
  }

  @Test("Table output line structure")
  func verifyTableStructure() throws {
    let record = RecordInfo(
      recordName: "verify-001",
      recordType: "Verify",
      fields: [
        "field1": .string("value1"),
        "field2": .string("value2")
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
  func formatUnknownType() throws {
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
  func formatRecordWithListField() throws {
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
  func verifyWhitespaceTrimming() throws {
    let record = RecordInfo(
      recordName: "trim-test",
      recordType: "Trim",
      fields: [
        "text1": .string("   leading"),
        "text2": .string("trailing   "),
        "text3": .string("   both   ")
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
  func formatConsecutiveWhitespace() throws {
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
  func formatRecordWithOnlyWhitespace() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Whitespace",
      fields: [
        "spaces": .string("     "),
        "tabs": .string("\t\t\t"),
        "newlines": .string("\n\n\n")
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
  func formatUserWithWhitespaceInEmail() throws {
    let user = UserInfo.test(
      userRecordName: "user-005",
      emailAddress: "test\n@example.com"
    )
    let formatter = TableFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("Email: test @example.com"))
  }

  @Test("Readable table format verification")
  func verifyReadableFormat() throws {
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
