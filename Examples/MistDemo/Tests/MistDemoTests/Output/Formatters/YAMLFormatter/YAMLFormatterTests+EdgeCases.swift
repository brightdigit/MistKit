//
//  YAMLFormatterTests+EdgeCases.swift
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

extension YAMLFormatterTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("Format record name with YAML keywords")
    internal func formatRecordNameWithYAMLKeywords() throws {
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
    internal func formatWithComplexFieldTypes() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Complex",
        fields: [
          "reference": .reference(.init(recordName: "ref-001")),
          "location": .location(.init(latitude: 37.7749, longitude: -122.4194)),
        ]
      )
      let formatter = YAMLFormatter()

      let output = try formatter.format(record)

      // Complex types should be converted to string representation
      #expect(output.contains("  location:"))
      #expect(output.contains("  reference:"))
    }

    @Test("YAML structure verification")
    internal func verifyYAMLStructure() throws {
      let record = RecordInfo(
        recordName: "verify-001",
        recordType: "Verify",
        fields: [
          "field1": .string("value1"),
          "field2": .string("value2"),
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
    internal func formatUnknownType() throws {
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
    internal func formatRecordWithListField() throws {
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
    internal func formatSimpleValue() throws {
      let record = RecordInfo(
        recordName: "simple-001",
        recordType: "Simple",
        fields: [
          "title": .string("SimpleTitle"),
          "status": .string("active"),
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
    internal func formatRecordWithKeywordCaseVariations() throws {
      let record = RecordInfo(
        recordName: "rec-001",
        recordType: "Keywords",
        fields: [
          "field1": .string("Yes"),
          "field2": .string("No"),
          "field3": .string("True"),
          "field4": .string("False"),
          "field5": .string("ON"),
          "field6": .string("OFF"),
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
}
