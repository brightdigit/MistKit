//
//  OutputFormatterFactoryTests+FactoryCreation.swift
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
  @Suite("Factory Creation")
  internal struct FactoryCreation {
    @Test("Create JSON formatter")
    internal func createJSONFormatter() {
      let formatter = OutputFormatterFactory.formatter(for: .json, pretty: false)

      #expect(formatter is JSONFormatter)
    }

    @Test("Create pretty JSON formatter")
    internal func createPrettyJSONFormatter() {
      let formatter = OutputFormatterFactory.formatter(for: .json, pretty: true)

      #expect(formatter is JSONFormatter)
    }

    @Test("Create CSV formatter")
    internal func createCSVFormatter() {
      let formatter = OutputFormatterFactory.formatter(for: .csv, pretty: false)

      #expect(formatter is CSVFormatter)
    }

    @Test("Create Table formatter")
    internal func createTableFormatter() {
      let formatter = OutputFormatterFactory.formatter(for: .table, pretty: false)

      #expect(formatter is TableFormatter)
    }

    @Test("Create YAML formatter")
    internal func createYAMLFormatter() {
      let formatter = OutputFormatterFactory.formatter(for: .yaml, pretty: false)

      #expect(formatter is YAMLFormatter)
    }

    @Test("Pretty flag ignored for CSV formatter")
    internal func prettyFlagIgnoredForCSV() {
      let formatter1 = OutputFormatterFactory.formatter(for: .csv, pretty: false)
      let formatter2 = OutputFormatterFactory.formatter(for: .csv, pretty: true)

      #expect(formatter1 is CSVFormatter)
      #expect(formatter2 is CSVFormatter)
    }

    @Test("Pretty flag ignored for Table formatter")
    internal func prettyFlagIgnoredForTable() {
      let formatter1 = OutputFormatterFactory.formatter(for: .table, pretty: false)
      let formatter2 = OutputFormatterFactory.formatter(for: .table, pretty: true)

      #expect(formatter1 is TableFormatter)
      #expect(formatter2 is TableFormatter)
    }

    @Test("Pretty flag ignored for YAML formatter")
    internal func prettyFlagIgnoredForYAML() {
      let formatter1 = OutputFormatterFactory.formatter(for: .yaml, pretty: false)
      let formatter2 = OutputFormatterFactory.formatter(for: .yaml, pretty: true)

      #expect(formatter1 is YAMLFormatter)
      #expect(formatter2 is YAMLFormatter)
    }
  }
}
