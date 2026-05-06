//
//  CurrentUserCommandTests+OutputFormat.swift
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
import Testing

@testable import MistDemoKit

extension CurrentUserCommandTests {
  @Suite("Output Format")
  internal struct OutputFormatTests {
    @Test("Output format enum has all expected cases")
    internal func outputFormatEnumCases() {
      let formats: [OutputFormat] = [.json, .table, .csv, .yaml]

      #expect(formats.count == 4)
      #expect(OutputFormat.json.rawValue == "json")
      #expect(OutputFormat.table.rawValue == "table")
      #expect(OutputFormat.csv.rawValue == "csv")
      #expect(OutputFormat.yaml.rawValue == "yaml")
    }

    @Test("Output format is case iterable")
    internal func outputFormatIsCaseIterable() {
      let allCases = OutputFormat.allCases

      #expect(allCases.count == 4)
      #expect(allCases.contains(.json))
      #expect(allCases.contains(.table))
      #expect(allCases.contains(.csv))
      #expect(allCases.contains(.yaml))
    }
  }
}
