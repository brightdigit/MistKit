//
//  OutputFormatterFactoryTests+OutputFormatEnum.swift
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
  @Suite("OutputFormat Enum")
  internal struct OutputFormatEnum {
    @Test("OutputFormat case count")
    internal func outputFormatCaseCount() {
      let allCases = OutputFormat.allCases

      #expect(allCases.count == 4)
      #expect(allCases.contains(.json))
      #expect(allCases.contains(.csv))
      #expect(allCases.contains(.table))
      #expect(allCases.contains(.yaml))
    }

    @Test("OutputFormat raw values")
    internal func outputFormatRawValues() {
      #expect(OutputFormat.json.rawValue == "json")
      #expect(OutputFormat.csv.rawValue == "csv")
      #expect(OutputFormat.table.rawValue == "table")
      #expect(OutputFormat.yaml.rawValue == "yaml")
    }

    @Test("OutputFormat from raw value")
    internal func outputFormatFromRawValue() {
      #expect(OutputFormat(rawValue: "json") == .json)
      #expect(OutputFormat(rawValue: "csv") == .csv)
      #expect(OutputFormat(rawValue: "table") == .table)
      #expect(OutputFormat(rawValue: "yaml") == .yaml)
      #expect(OutputFormat(rawValue: "invalid") == nil)
    }

    @Test("OutputFormat createFormatter method")
    internal func outputFormatCreateFormatter() {
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
    internal func outputFormatCreateFormatterWithPretty() {
      let prettyFormatter = OutputFormat.json.createFormatter(pretty: true)
      let compactFormatter = OutputFormat.json.createFormatter(pretty: false)

      #expect(prettyFormatter is JSONFormatter)
      #expect(compactFormatter is JSONFormatter)
    }
  }
}
