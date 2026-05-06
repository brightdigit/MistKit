//
//  YAMLEscaperTests+ComplexEdgeCases.swift
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

extension YAMLEscaperTests {
  @Suite("Complex Edge Cases")
  internal struct ComplexEdgeCases {
    private let escaper = YAMLEscaper()

    @Test("String that looks like YAML but isn't")
    internal func yamlLikeString() {
      let input = "yes this is true"
      let output = escaper.escape(input)
      // Should not be quoted because "yes" is part of a larger string
      #expect(output == "yes this is true")
    }

    @Test("Number within text is not escaped")
    internal func numberWithinText() {
      let input = "test123abc"
      let output = escaper.escape(input)
      #expect(output == "test123abc")
    }

    @Test("String with special character in middle needs escaping")
    internal func specialCharInMiddle() {
      let input = "test:value"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("\""))
    }

    @Test("Complex multi-line with quotes and escapes")
    internal func complexMultiLine() {
      let input = "Line 1: \"quoted\"\nLine 2: with\\backslash"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
    }

    @Test("Single newline character")
    internal func singleNewline() {
      let input = "\n"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
    }

    @Test("String with only whitespace and newline")
    internal func whitespaceWithNewline() {
      let input = "  \n  "
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
    }
  }
}
