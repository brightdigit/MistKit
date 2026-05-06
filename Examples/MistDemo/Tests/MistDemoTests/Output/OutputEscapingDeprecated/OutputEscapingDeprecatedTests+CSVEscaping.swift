//
//  OutputEscapingDeprecatedTests+CSVEscaping.swift
//  MistDemo
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

extension OutputEscapingDeprecatedTests {
  @Suite("CSV Escaping")
  internal struct CSVEscaping {
    @Test("CSV escape handles simple strings without special characters")
    internal func csvEscapeSimpleString() {
      let input = "simple text"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "simple text")
    }

    @Test("CSV escape handles comma")
    internal func csvEscapeComma() {
      let input = "text,with,commas"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"text,with,commas\"")
    }

    @Test("CSV escape handles quotes")
    internal func csvEscapeQuotes() {
      let input = "text with \"quotes\""
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"text with \"\"quotes\"\"\"")
    }

    @Test("CSV escape handles newlines")
    internal func csvEscapeNewlines() {
      let input = "text\nwith\nnewlines"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"text\nwith\nnewlines\"")
    }

    @Test("CSV escape handles tabs")
    internal func csvEscapeTabs() {
      let input = "text\twith\ttabs"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"text\twith\ttabs\"")
    }

    @Test("CSV escape handles carriage returns")
    internal func csvEscapeCarriageReturns() {
      let input = "text\rwith\rCR"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"text\rwith\rCR\"")
    }

    @Test("CSV escape handles mixed special characters")
    internal func csvEscapeMixed() {
      let input = "Name: \"John, Jr.\"\nAge: 30"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "\"Name: \"\"John, Jr.\"\"\nAge: 30\"")
    }

    @Test("CSV escape handles empty string")
    internal func csvEscapeEmpty() {
      let input = ""
      let result = OutputEscaping.csvEscape(input)
      #expect(result.isEmpty)
    }

    @Test("CSV escape is idempotent for simple strings")
    internal func csvEscapeIdempotent() {
      let input = "simple text"
      let once = OutputEscaping.csvEscape(input)
      let twice = OutputEscaping.csvEscape(once)
      #expect(once == input)
      #expect(twice == once)  // Truly idempotent: no special chars, no quoting on second pass
    }
  }
}
