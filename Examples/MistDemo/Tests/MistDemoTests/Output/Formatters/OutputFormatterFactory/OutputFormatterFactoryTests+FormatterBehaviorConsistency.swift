//
//  OutputFormatterFactoryTests+FormatterBehaviorConsistency.swift
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
  @Suite("Formatter Behavior Consistency")
  internal struct FormatterBehaviorConsistency {
    @Test("All formatters handle empty fields")
    internal func allFormattersHandleEmptyFields() throws {
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
    internal func allFormattersHandleSpecialCharacters() throws {
      let record = RecordInfo(
        recordName: "special-001",
        recordType: "Special",
        fields: [
          "quotes": .string("He said \"hello\""),
          "newlines": .string("Line1\nLine2"),
          "commas": .string("a,b,c"),
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
    internal func allFormattersHandleComplexFieldTypes() throws {
      let record = RecordInfo(
        recordName: "complex-001",
        recordType: "Complex",
        fields: [
          "reference": .reference(.init(recordName: "ref-001")),
          "location": .location(.init(latitude: 37.7749, longitude: -122.4194)),
          "list": .list([.string("item1"), .string("item2")]),
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
    internal func allFormattersHandleMinimalUserInfo() throws {
      let user = UserInfo.test(userRecordName: "user-min")

      for format in OutputFormat.allCases {
        let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
        let output = try formatter.format(user)

        #expect(!output.isEmpty)
        #expect(output.contains("user-min"))
      }
    }

    @Test("Factory produces working formatters for all formats")
    internal func factoryProducesWorkingFormatters() throws {
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
  }
}
