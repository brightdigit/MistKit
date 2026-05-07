//
//  CSVEscaperTests+Combination.swift
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

extension CSVEscaperTests {
  @Suite("Combination")
  internal struct Combination {
    private let escaper = CSVEscaper()

    @Test("String with comma and quote")
    internal func commaAndQuote() {
      let input = "Value, \"quoted\""
      let output = escaper.escape(input)
      #expect(output == "\"Value, \"\"quoted\"\"\"")
    }

    @Test("String with all special characters")
    internal func allSpecialCharacters() {
      let input = "Test,\"value\"\nwith\ttab\rand more"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("\""))
      #expect(output.hasSuffix("\""))
      #expect(output.contains("\"\"value\"\""))
    }

    @Test("Complex RFC 4180 example")
    internal func complexRFC4180() {
      let input = "1997,Ford,E350,\"Super, \"\"luxurious\"\" truck\""
      let output = escaper.escape(input)
      #expect(output.hasPrefix("\""))
      #expect(output.hasSuffix("\""))
    }
  }
}
