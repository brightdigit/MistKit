//
//  OutputFormatterFactoryTests+EdgeCases.swift
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
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("Formatters handle Unicode characters")
    internal func formattersHandleUnicode() throws {
      let record = RecordInfo(
        recordName: "unicode-001",
        recordType: "Unicode",
        fields: [
          "emoji": .string("😀🎉✨"),
          "chinese": .string("你好世界"),
          "arabic": .string("مرحبا"),
          "accents": .string("café résumé"),
        ]
      )

      for format in OutputFormat.allCases {
        let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
        let output = try formatter.format(record)

        #expect(!output.isEmpty)
      }
    }

    @Test("Formatters handle very long strings")
    internal func formattersHandleVeryLongStrings() throws {
      let longString = String(repeating: "a", count: 10_000)
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
    internal func formattersHandleManyFields() throws {
      var fields: [String: FieldValue] = [:]
      for index in 0..<100 {
        fields["field\(index)"] = .string("value\(index)")
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
    internal func defaultPrettyParameterIsFalse() throws {
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
}
