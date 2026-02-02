//
//  YAMLFormatterTests.swift
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

@Suite("YAMLFormatter Tests")
struct YAMLFormatterTests {
  // MARK: - RecordInfo Tests

  @Test("Format basic RecordInfo with YAML structure")
  func formatBasicRecord() throws {
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
  func formatRecordWithStringFields() throws {
    let record = RecordInfo(
      recordName: "task-001",
      recordType: "Task",
      fields: [
        "title": .string("Buy groceries"),
        "status": .string("pending")
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
  func formatRecordWithNumericFields() throws {
    let record = RecordInfo(
      recordName: "item-001",
      recordType: "Product",
      fields: [
        "price": .double(19.99),
        "quantity": .int64(42)
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("  price:"))
    #expect(output.contains("  quantity:"))
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
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("recordName: empty-001"))
    #expect(output.contains("recordType: Empty"))
    #expect(!output.contains("fields:"))
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
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Fields should be indented with 2 spaces
    #expect(output.contains("fields:\n"))
    #expect(output.contains("  field1: value1"))
  }

  // MARK: - YAML Escaping Tests

  @Test("Format RecordInfo with colon in value")
  func formatRecordWithColonInValue() throws {
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
  func formatRecordWithHashInValue() throws {
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
  func formatRecordWithQuotesInValue() throws {
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
  func formatRecordWithNewlineInValue() throws {
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
  func formatRecordWithBackslashInValue() throws {
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
  func formatRecordWithBooleanKeywords() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Keywords",
      fields: [
        "yes_field": .string("yes"),
        "no_field": .string("no"),
        "true_field": .string("true"),
        "false_field": .string("false")
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
  func formatRecordWithNumericString() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Numeric",
      fields: [
        "code": .string("12345"),
        "decimal": .string("3.14")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Numeric strings should be quoted to preserve as strings
    #expect(output.contains("\"12345\""))
    #expect(output.contains("\"3.14\""))
  }

  @Test("Format RecordInfo with empty string value")
  func formatRecordWithEmptyStringValue() throws {
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
  func formatRecordWithLeadingWhitespace() throws {
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
  func formatRecordWithTrailingWhitespace() throws {
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
  func formatRecordWithSpecialYAMLChars() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Special",
      fields: [
        "brackets": .string("[array]"),
        "braces": .string("{object}"),
        "ampersand": .string("&reference"),
        "asterisk": .string("*alias")
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
  func formatRecordWithTabCharacter() throws {
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
  func formatRecordWithCarriageReturn() throws {
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
  func formatRecordWithNullKeyword() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Null",
      fields: [
        "value": .string("null"),
        "tilde": .string("~")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // YAML null keywords should be quoted
    #expect(output.contains("\"null\""))
    #expect(output.contains("\"~\""))
  }

  // MARK: - Multiline String Tests

  @Test("Format RecordInfo with multiline block scalar")
  func formatRecordWithMultilineBlockScalar() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Multiline",
      fields: [
        "description": .string("First line\nSecond line\nThird line")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Should use literal block scalar
    #expect(output.contains("  description: |"))
    #expect(output.contains("    First line"))
    #expect(output.contains("    Second line"))
    #expect(output.contains("    Third line"))
  }

  @Test("Format RecordInfo with multiline and empty lines")
  func formatRecordWithMultilineAndEmptyLines() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Multiline",
      fields: [
        "text": .string("Line 1\n\nLine 3")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Should preserve empty lines in block scalar
    #expect(output.contains("  text: |"))
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
    let formatter = YAMLFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("userRecordName: user-001"))
    #expect(output.contains("firstName: John"))
    #expect(output.contains("lastName: Doe"))
    #expect(output.contains("emailAddress: john.doe@example.com"))
  }

  @Test("Format UserInfo with minimal fields")
  func formatUserWithMinimalFields() throws {
    let user = UserInfo.test(userRecordName: "user-min")
    let formatter = YAMLFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("userRecordName: user-min"))
    #expect(!output.contains("firstName:"))
    #expect(!output.contains("lastName:"))
    #expect(!output.contains("emailAddress:"))
  }

  @Test("Format UserInfo with partial fields")
  func formatUserWithPartialFields() throws {
    let user = UserInfo.test(
      userRecordName: "user-002",
      firstName: "Jane",
      emailAddress: "jane@example.com"
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("userRecordName: user-002"))
    #expect(output.contains("firstName: Jane"))
    #expect(!output.contains("lastName:"))
    #expect(output.contains("emailAddress: jane@example.com"))
  }

  @Test("Format UserInfo with special characters in name")
  func formatUserWithSpecialCharsInName() throws {
    let user = UserInfo.test(
      userRecordName: "user-003",
      firstName: "O'Brien",
      lastName: "Smith: Jr."
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("firstName: O'Brien"))
    #expect(output.contains("\"Smith: Jr.\""))  // Colon should cause quoting
  }

  @Test("Format UserInfo with email containing special chars")
  func formatUserWithSpecialCharsInEmail() throws {
    let user = UserInfo.test(
      userRecordName: "user-004",
      emailAddress: "test+tag@example.com"
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("emailAddress: test+tag@example.com"))
  }

  // MARK: - Edge Cases

  @Test("Format record name with YAML keywords")
  func formatRecordNameWithYAMLKeywords() throws {
    let record = RecordInfo(
      recordName: "true",
      recordType: "yes",
      fields: [:]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // YAML keywords should be quoted
    #expect(output.contains("recordName: \"true\""))
    #expect(output.contains("recordType: \"yes\""))
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
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Complex types should be converted to string representation
    #expect(output.contains("  location:"))
    #expect(output.contains("  reference:"))
  }

  @Test("YAML structure verification")
  func verifyYAMLStructure() throws {
    let record = RecordInfo(
      recordName: "verify-001",
      recordType: "Verify",
      fields: [
        "field1": .string("value1"),
        "field2": .string("value2")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

    // Verify YAML structure
    #expect(lines[0].hasPrefix("recordName:"))
    #expect(lines[1].hasPrefix("recordType:"))
    #expect(lines[2] == "fields:")
    #expect(lines[3].hasPrefix("  "))  // First field should be indented
  }

  @Test("Format fallback to JSON for unknown type")
  func formatUnknownType() throws {
    struct UnknownType: Encodable {
      let data: String
    }

    let unknown = UnknownType(data: "test")
    let formatter = YAMLFormatter()

    let output = try formatter.format(unknown)

    // Should fall back to pretty JSON format
    #expect(output.contains("data"))
    #expect(output.contains("test"))
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
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("  tags:"))
  }

  @Test("Format simple value requiring no escaping")
  func formatSimpleValue() throws {
    let record = RecordInfo(
      recordName: "simple-001",
      recordType: "Simple",
      fields: [
        "title": .string("SimpleTitle"),
        "status": .string("active")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // Simple values should not be quoted
    #expect(output.contains("  title: SimpleTitle"))
    #expect(output.contains("  status: active"))
    #expect(!output.contains("\"SimpleTitle\""))
    #expect(!output.contains("\"active\""))
  }

  @Test("Format RecordInfo with case variations of YAML keywords")
  func formatRecordWithKeywordCaseVariations() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "Keywords",
      fields: [
        "field1": .string("Yes"),
        "field2": .string("No"),
        "field3": .string("True"),
        "field4": .string("False"),
        "field5": .string("ON"),
        "field6": .string("OFF")
      ]
    )
    let formatter = YAMLFormatter()

    let output = try formatter.format(record)

    // All case variations of YAML keywords should be quoted
    #expect(output.contains("\"Yes\""))
    #expect(output.contains("\"No\""))
    #expect(output.contains("\"True\""))
    #expect(output.contains("\"False\""))
    #expect(output.contains("\"ON\""))
    #expect(output.contains("\"OFF\""))
  }
}
