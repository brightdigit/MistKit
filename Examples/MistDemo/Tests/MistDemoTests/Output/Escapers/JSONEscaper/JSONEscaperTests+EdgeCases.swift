//
//  JSONEscaperTests+EdgeCases.swift
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

extension JSONEscaperTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    private let escaper = JSONEscaper()

    @Test("String with only escape characters")
    internal func onlyEscapeCharacters() {
      let input = "\n\r\t"
      let output = escaper.escape(input)
      #expect(output == "\\n\\r\\t")
    }

    @Test("Long string with escapes")
    internal func longStringWithEscapes() {
      let input = String(repeating: "\n", count: 100)
      let output = escaper.escape(input)
      #expect(output == String(repeating: "\\n", count: 100))
    }

    @Test("Normal characters not escaped")
    internal func normalCharactersNotEscaped() {
      let input = "!@#$%^&*()_+-=[]{}|;':,.<>?/"
      let output = escaper.escape(input)
      // These characters should pass through unchanged
      #expect(output == input)
    }

    @Test("Escape sequence at start")
    internal func escapeAtStart() {
      let input = "\nStart"
      let output = escaper.escape(input)
      #expect(output == "\\nStart")
    }

    @Test("Escape sequence at end")
    internal func escapeAtEnd() {
      let input = "End\n"
      let output = escaper.escape(input)
      #expect(output == "End\\n")
    }

    @Test("Complex real-world JSON string")
    internal func complexRealWorld() {
      let input = "{\"key\": \"value\",\n\t\"nested\": {\"path\": \"C:\\\\Users\\\\test\"}}"
      let output = escaper.escape(input)
      #expect(output.contains("\\\""))
      #expect(output.contains("\\n"))
      #expect(output.contains("\\t"))
      #expect(output.contains("\\\\"))
    }
  }
}
