//
//  OutputFormatterFactoryTests+Integration.swift
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
  @Suite("Integration")
  internal struct Integration {
    @Test("All formatters can format RecordInfo")
    internal func allFormattersCanFormatRecordInfo() throws {
      let record = RecordInfo(
        recordName: "integration-001",
        recordType: "Integration",
        fields: [
          "string": .string("test"),
          "number": .int64(42),
        ]
      )

      for format in OutputFormat.allCases {
        let formatter = OutputFormatterFactory.formatter(for: format, pretty: false)
        let output = try formatter.format(record)

        #expect(!output.isEmpty)
      }
    }

    @Test("All formatters can format UserInfo")
    internal func allFormattersCanFormatUserInfo() throws {
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
    internal func differentFormattersProduceDifferentOutput() throws {
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
    internal func jsonPrettyVsCompactDifferent() throws {
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
  }
}
