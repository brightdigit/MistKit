//
//  OutputFormatterFactoryTests.swift
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

@Suite("OutputFormatterFactory Tests")
struct OutputFormatterFactoryTests {
  // MARK: - Factory Creation Tests

  @Test("Create JSON formatter")
  func createJSONFormatter() {
    let formatter = OutputFormatterFactory.formatter(for: .json, pretty: false)

    #expect(formatter is JSONFormatter)
  }

  @Test("Create pretty JSON formatter")
  func createPrettyJSONFormatter() {
    let formatter = OutputFormatterFactory.formatter(for: .json, pretty: true)

    #expect(formatter is JSONFormatter)
  }

  @Test("Create CSV formatter")
  func createCSVFormatter() {
    let formatter = OutputFormatterFactory.formatter(for: .csv, pretty: false)

    #expect(formatter is CSVFormatter)
  }

  @Test("Create Table formatter")
  func createTableFormatter() {
    let formatter = OutputFormatterFactory.formatter(for: .table, pretty: false)

    #expect(formatter is TableFormatter)
  }

  @Test("Create YAML formatter")
  func createYAMLFormatter() {
    let formatter = OutputFormatterFactory.formatter(for: .yaml, pretty: false)

    #expect(formatter is YAMLFormatter)
  }

  @Test("Pretty flag ignored for CSV formatter")
  func prettyFlagIgnoredForCSV() {
    let formatter1 = OutputFormatterFactory.formatter(for: .csv, pretty: false)
    let formatter2 = OutputFormatterFactory.formatter(for: .csv, pretty: true)

    #expect(formatter1 is CSVFormatter)
    #expect(formatter2 is CSVFormatter)
  }

  @Test("Pretty flag ignored for Table formatter")
  func prettyFlagIgnoredForTable() {
    let formatter1 = OutputFormatterFactory.formatter(for: .table, pretty: false)
    let formatter2 = OutputFormatterFactory.formatter(for: .table, pretty: true)

    #expect(formatter1 is TableFormatter)
    #expect(formatter2 is TableFormatter)
  }

  @Test("Pretty flag ignored for YAML formatter")
  func prettyFlagIgnoredForYAML() {
    let formatter1 = OutputFormatterFactory.formatter(for: .yaml, pretty: false)
    let formatter2 = OutputFormatterFactory.formatter(for: .yaml, pretty: true)

    #expect(formatter1 is YAMLFormatter)
    #expect(formatter2 is YAMLFormatter)
  }

  // MARK: - Format-Specific Output Tests

  @Test("JSON formatter produces valid JSON")
  func jsonFormatterProducesValidJSON() throws {
    let formatter = OutputFormatterFactory.formatter(for: .json, pretty: false)
    let record = RecordInfo(
      recordName: "test-001",
      recordType: "Test",
      fields: ["field": .string("value")]
    )

    let output = try formatter.format(record)

    // Should be valid JSON
    #expect(output.contains("{"))
    #expect(output.contains("}"))
    #expect(output.contains("\""))

    // Should be parseable as JSON
    let data = Data(output.utf8)
    let _ = try JSONSerialization.jsonObject(with: data)
  }

  @Test("CSV formatter produces CSV with headers")
  func csvFormatterProducesCSVWithHeaders() throws {
    let formatter = OutputFormatterFactory.formatter(for: .csv, pretty: false)
    let record = RecordInfo(
      recordName: "test-001",
      recordType: "Test",
      fields: ["field": .string("value")]
    )

    let output = try formatter.format(record)

    // Should have CSV header
    #expect(output.hasPrefix("Field,Value\n"))
  }

  @Test("Table formatter produces human-readable output")
  func tableFormatterProducesReadableOutput() throws {
    let formatter = OutputFormatterFactory.formatter(for: .table, pretty: false)
    let record = RecordInfo(
      recordName: "test-001",
      recordType: "Test",
      fields: ["field": .string("value")]
    )

    let output = try formatter.format(record)

    // Should have human-readable labels
    #expect(output.contains("Record Name:"))
    #expect(output.contains("Record Type:"))
  }

  @Test("YAML formatter produces YAML structure")
  func yamlFormatterProducesYAMLStructure() throws {
    let formatter = OutputFormatterFactory.formatter(for: .yaml, pretty: false)
    let record = RecordInfo(
      recordName: "test-001",
      recordType: "Test",
      fields: ["field": .string("value")]
    )

    let output = try formatter.format(record)

    // Should have YAML structure
    #expect(output.contains("recordName:"))
    #expect(output.contains("recordType:"))
  }

  // MARK: - OutputFormat Enum Tests

  @Test("OutputFormat case count")
  func outputFormatCaseCount() {
    let allCases = OutputFormat.allCases

    #expect(allCases.count == 4)
    #expect(allCases.contains(.json))
    #expect(allCases.contains(.csv))
    #expect(allCases.contains(.table))
    #expect(allCases.contains(.yaml))
  }

  @Test("OutputFormat raw values")
  func outputFormatRawValues() {
    #expect(OutputFormat.json.rawValue == "json")
    #expect(OutputFormat.csv.rawValue == "csv")
    #expect(OutputFormat.table.rawValue == "table")
    #expect(OutputFormat.yaml.rawValue == "yaml")
  }

  @Test("OutputFormat from raw value")
  func outputFormatFromRawValue() {
    #expect(OutputFormat(rawValue: "json") == .json)
    #expect(OutputFormat(rawValue: "csv") == .csv)
    #expect(OutputFormat(rawValue: "table") == .table)
    #expect(OutputFormat(rawValue: "yaml") == .yaml)
    #expect(OutputFormat(rawValue: "invalid") == nil)
  }

  @Test("OutputFormat createFormatter method")
  func outputFormatCreateFormatter() {
    let jsonFormatter = OutputFormat.json.createFormatter(pretty: false)
    let csvFormatter = OutputFormat.csv.createFormatter()
    let tableFormatter = OutputFormat.table.createFormatter()
    let yamlFormatter = OutputFormat.yaml.createFormatter()

    #expect(jsonFormatter is JSONFormatter)
    #expect(csvFormatter is CSVFormatter)
    #expect(tableFormatter is TableFormatter)
    #expect(yamlFormatter is YAMLFormatter)
  }

  @Test("OutputFormat createFormatter with pretty flag")
  func outputFormatCreateFormatterWithPretty() {
    let prettyFormatter = OutputFormat.json.createFormatter(pretty: true)
    let compactFormatter = OutputFormat.json.createFormatter(pretty: false)

    #expect(prettyFormatter is JSONFormatter)
    #expect(compactFormatter is JSONFormatter)
  }

  // MARK: - Integration Tests

  @Test("All formatters can format RecordInfo")
  func allFormattersCanFormatRecordInfo() throws {
    let record = RecordInfo(
      recordName: "integration-001",
      recordType: "Integration",
      fields: [
        "string": .string("test"),
        "number": .int64(42)
      ]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(record)

      #expect(!output.isEmpty)
    }
  }

  @Test("All formatters can format UserInfo")
  func allFormattersCanFormatUserInfo() throws {
    let user = UserInfo.test(
      userRecordName: "user-001",
      firstName: "Test",
      lastName: "User",
      emailAddress: "test@example.com"
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(user)

      #expect(!output.isEmpty)
    }
  }

  @Test("Different formatters produce different output")
  func differentFormattersProduceDifferentOutput() throws {
    let record = RecordInfo(
      recordName: "diff-001",
      recordType: "Diff",
      fields: ["field": .string("value")]
    )

    let jsonOutput = try OutputFormatterFactory.formatter(for: .json, pretty: false)
      .format(record)
    let csvOutput = try OutputFormatterFactory.formatter(for: .csv, pretty: false)
      .format(record)
    let tableOutput = try OutputFormatterFactory.formatter(for: .table, pretty: false)
      .format(record)
    let yamlOutput = try OutputFormatterFactory.formatter(for: .yaml, pretty: false)
      .format(record)

    // All outputs should be different
    #expect(jsonOutput != csvOutput)
    #expect(jsonOutput != tableOutput)
    #expect(jsonOutput != yamlOutput)
    #expect(csvOutput != tableOutput)
    #expect(csvOutput != yamlOutput)
    #expect(tableOutput != yamlOutput)
  }

  @Test("JSON pretty vs compact produces different output")
  func jsonPrettyVsCompactDifferent() throws {
    let record = RecordInfo(
      recordName: "pretty-001",
      recordType: "Pretty",
      fields: ["field": .string("value")]
    )

    let prettyOutput = try OutputFormatterFactory.formatter(for: .json, pretty: true)
      .format(record)
    let compactOutput = try OutputFormatterFactory.formatter(for: .json, pretty: false)
      .format(record)

    // Pretty should have more whitespace
    #expect(prettyOutput.count > compactOutput.count)
    #expect(prettyOutput.contains("\n"))
  }

  // MARK: - Formatter Behavior Consistency

  @Test("All formatters handle empty fields")
  func allFormattersHandleEmptyFields() throws {
    let record = RecordInfo(
      recordName: "empty-001",
      recordType: "Empty",
      fields: [:]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(record)

      #expect(!output.isEmpty)
      #expect(output.contains("empty-001"))
    }
  }

  @Test("All formatters handle special characters")
  func allFormattersHandleSpecialCharacters() throws {
    let record = RecordInfo(
      recordName: "special-001",
      recordType: "Special",
      fields: [
        "quotes": .string("He said \"hello\""),
        "newlines": .string("Line1\nLine2"),
        "commas": .string("a,b,c")
      ]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)

      // Should not throw
      let output = try formatter.format(record)
      #expect(!output.isEmpty)
    }
  }

  @Test("All formatters handle complex field types")
  func allFormattersHandleComplexFieldTypes() throws {
    let record = RecordInfo(
      recordName: "complex-001",
      recordType: "Complex",
      fields: [
        "reference": .reference(.init(recordName: "ref-001")),
        "location": .location(.init(latitude: 37.7749, longitude: -122.4194)),
        "list": .list([.string("item1"), .string("item2")])
      ]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)

      // Should not throw
      let output = try formatter.format(record)
      #expect(!output.isEmpty)
    }
  }

  @Test("All formatters handle minimal UserInfo")
  func allFormattersHandleMinimalUserInfo() throws {
    let user = UserInfo.test(userRecordName: "user-min")

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(user)

      #expect(!output.isEmpty)
      #expect(output.contains("user-min"))
    }
  }

  @Test("Factory produces working formatters for all formats")
  func factoryProducesWorkingFormatters() throws {
    let testData = RecordInfo(
      recordName: "test",
      recordType: "Test",
      fields: ["key": .string("value")]
    )

    // JSON
    let jsonFormatter = OutputFormatterFactory.formatter(for: .json)
    let jsonOutput = try jsonFormatter.format(testData)
    #expect(jsonOutput.contains("test"))

    // CSV
    let csvFormatter = OutputFormatterFactory.formatter(for: .csv)
    let csvOutput = try csvFormatter.format(testData)
    #expect(csvOutput.contains("Field,Value"))

    // Table
    let tableFormatter = OutputFormatterFactory.formatter(for: .table)
    let tableOutput = try tableFormatter.format(testData)
    #expect(tableOutput.contains("Record Name:"))

    // YAML
    let yamlFormatter = OutputFormatterFactory.formatter(for: .yaml)
    let yamlOutput = try yamlFormatter.format(testData)
    #expect(yamlOutput.contains("recordName:"))
  }

  // MARK: - Edge Cases

  @Test("Formatters handle Unicode characters")
  func formattersHandleUnicode() throws {
    let record = RecordInfo(
      recordName: "unicode-001",
      recordType: "Unicode",
      fields: [
        "emoji": .string("😀🎉✨"),
        "chinese": .string("你好世界"),
        "arabic": .string("مرحبا"),
        "accents": .string("café résumé")
      ]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(record)

      #expect(!output.isEmpty)
    }
  }

  @Test("Formatters handle very long strings")
  func formattersHandleVeryLongStrings() throws {
    let longString = String(repeating: "a", count: 10000)
    let record = RecordInfo(
      recordName: "long-001",
      recordType: "Long",
      fields: ["long": .string(longString)]
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(record)

      #expect(!output.isEmpty)
      #expect(output.count >= longString.count)
    }
  }

  @Test("Formatters handle many fields")
  func formattersHandleManyFields() throws {
    var fields: [String: FieldValue] = [:]
    for i in 0..<100 {
      fields["field\(i)"] = .string("value\(i)")
    }

    let record = RecordInfo(
      recordName: "many-001",
      recordType: "Many",
      fields: fields
    )

    for format in OutputFormat.allCases {
      let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
      let output = try formatter.format(record)

      #expect(!output.isEmpty)
    }
  }

  @Test("Default pretty parameter is false")
  func defaultPrettyParameterIsFalse() throws {
    let record = RecordInfo(
      recordName: "default-001",
      recordType: "Default",
      fields: ["field": .string("value")]
    )

    // Call without pretty parameter (defaults to false)
    let defaultFormatter = OutputFormatterFactory.formatter(for: .json)
    let defaultOutput = try defaultFormatter.format(record)

    // Call with explicit pretty: false
    let explicitFormatter = OutputFormatterFactory.formatter(for: .json, pretty: false)
    let explicitOutput = try explicitFormatter.format(record)

    // Both should produce compact output (single line)
    let defaultLines = defaultOutput.components(separatedBy: "\n").filter { !$0.isEmpty }
    let explicitLines = explicitOutput.components(separatedBy: "\n").filter { !$0.isEmpty }

    #expect(defaultLines.count == 1)
    #expect(explicitLines.count == 1)
  }
}
