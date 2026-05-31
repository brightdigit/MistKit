//
//  OutputFormatterFactoryTests+FormatSpecificOutput.swift
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

extension OutputFormatterFactoryTests {
  @Suite("Format-Specific Output")
  internal struct FormatSpecificOutput {
    @Test("JSON formatter produces valid JSON")
    internal func jsonFormatterProducesValidJSON() throws {
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
      _ = try JSONSerialization.jsonObject(with: data)
    }

    @Test("CSV formatter produces CSV with headers")
    internal func csvFormatterProducesCSVWithHeaders() throws {
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
    internal func tableFormatterProducesReadableOutput() throws {
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
    internal func yamlFormatterProducesYAMLStructure() throws {
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
  }
}
