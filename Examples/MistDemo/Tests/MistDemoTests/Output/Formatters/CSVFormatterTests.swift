//
//  CSVFormatterTests.swift
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

@Suite("CSVFormatter Tests")
struct CSVFormatterTests {
  // MARK: - RecordInfo Tests

  @Test("Format basic RecordInfo with CSV headers")
  func formatBasicRecord() throws {
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
  func formatRecordWithStringFields() throws {
    let record = RecordInfo(
      recordName: "task-001",
      recordType: "Task",
      fields: [
        "title": .string("Buy groceries"),
        "status": .string("pending")
      ]
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("Field,Value\n"))
    #expect(output.contains("status,"))
    #expect(output.contains("title,"))
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
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("price,"))
    #expect(output.contains("quantity,"))
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
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    #expect(output.hasPrefix("Field,Value\n"))
    #expect(output.contains("recordName,empty-001"))
    #expect(output.contains("recordType,Empty"))

    // Should only have header + 2 lines (recordName, recordType)
    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
    #expect(lines.count == 3)
  }

  // MARK: - CSV Escaping Tests

  @Test("Format RecordInfo with comma in field value")
  func formatRecordWithCommaInValue() throws {
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
  func formatRecordWithQuoteInValue() throws {
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
  func formatRecordWithNewlineInValue() throws {
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
  func formatRecordWithTabInValue() throws {
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
  func formatRecordWithMultipleSpecialChars() throws {
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
  func formatRecordWithSimpleValue() throws {
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
  func formatRecordNameWithSpecialChars() throws {
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

  // MARK: - UserInfo Tests

  @Test("Format basic UserInfo")
  func formatBasicUser() throws {
    let user = UserInfo.test(
      userRecordName: "user-001",
      firstName: "John",
      lastName: "Doe",
      emailAddress: "john.doe@example.com"
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(user)

    #expect(output.hasPrefix("Field,Value\n"))
    #expect(output.contains("userRecordName,user-001"))
    #expect(output.contains("firstName,John"))
    #expect(output.contains("lastName,Doe"))
    #expect(output.contains("emailAddress,john.doe@example.com"))
  }

  @Test("Format UserInfo with minimal fields")
  func formatUserWithMinimalFields() throws {
    let user = UserInfo.test(userRecordName: "user-min")
    let formatter = CSVFormatter()

    let output = try formatter.format(user)

    #expect(output.hasPrefix("Field,Value\n"))
    #expect(output.contains("userRecordName,user-min"))
    #expect(!output.contains("firstName"))
    #expect(!output.contains("lastName"))
    #expect(!output.contains("emailAddress"))

    // Should only have header + 1 line (userRecordName)
    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }
    #expect(lines.count == 2)
  }

  @Test("Format UserInfo with partial fields")
  func formatUserWithPartialFields() throws {
    let user = UserInfo.test(
      userRecordName: "user-002",
      firstName: "Jane"
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("userRecordName,user-002"))
    #expect(output.contains("firstName,Jane"))
    #expect(!output.contains("lastName"))
    #expect(!output.contains("emailAddress"))
  }

  @Test("Format UserInfo with special characters in name")
  func formatUserWithSpecialCharsInName() throws {
    let user = UserInfo.test(
      userRecordName: "user-003",
      firstName: "O'Brien",
      lastName: "Smith, Jr."
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("firstName,O'Brien"))
    #expect(output.contains("\"Smith, Jr.\""))
  }

  @Test("Format UserInfo with special characters in email")
  func formatUserWithSpecialCharsInEmail() throws {
    let user = UserInfo.test(
      userRecordName: "user-004",
      emailAddress: "test+tag@example.com"
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(user)

    #expect(output.contains("emailAddress,test+tag@example.com"))
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
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    // Empty strings should still produce valid CSV
    #expect(output.hasPrefix("Field,Value\n"))
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
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    // Complex types should be converted to string representation
    #expect(output.contains("location,"))
    #expect(output.contains("reference,"))
  }

  @Test("CSV output structure verification")
  func verifyCSVStructure() throws {
    let record = RecordInfo(
      recordName: "verify-001",
      recordType: "Verify",
      fields: [
        "field1": .string("value1"),
        "field2": .string("value2")
      ]
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    let lines = output.components(separatedBy: "\n").filter { !$0.isEmpty }

    // Verify structure: header + recordName + recordType + fields
    #expect(lines.count == 5)
    #expect(lines[0] == "Field,Value")
  }

  @Test("Format fallback to JSON for unknown type")
  func formatUnknownType() throws {
    struct UnknownType: Encodable {
      let data: String
    }

    let unknown = UnknownType(data: "test")
    let formatter = CSVFormatter()

    let output = try formatter.format(unknown)

    // Should fall back to JSON format
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
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("tags,"))
  }

  @Test("Format RecordInfo with nil recordChangeTag")
  func formatRecordWithNilChangeTag() throws {
    let record = RecordInfo(
      recordName: "rec-001",
      recordType: "NoTag",
      recordChangeTag: nil,
      fields: [:]
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    #expect(output.contains("recordName,rec-001"))
    #expect(output.contains("recordType,NoTag"))
  }

  @Test("RFC 4180 compliance verification")
  func verifyRFC4180Compliance() throws {
    let record = RecordInfo(
      recordName: "rfc-test",
      recordType: "RFC4180",
      fields: [
        "standard": .string("normal"),
        "comma": .string("a,b"),
        "quote": .string("a\"b"),
        "newline": .string("a\nb"),
        "crlf": .string("a\r\nb"),
        "complex": .string("a,\"b\"\nc")
      ]
    )
    let formatter = CSVFormatter()

    let output = try formatter.format(record)

    // Verify RFC 4180 compliance
    #expect(output.contains("standard,normal"))
    #expect(output.contains("\"a,b\""))
    #expect(output.contains("\"a\"\"b\"\""))
    #expect(output.contains("\"a\nb\""))
    #expect(output.contains("\"a\r\nb\""))
  }
}
