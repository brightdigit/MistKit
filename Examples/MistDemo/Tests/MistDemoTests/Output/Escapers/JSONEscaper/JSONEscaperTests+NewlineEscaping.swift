//
//  JSONEscaperTests+NewlineEscaping.swift
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
  @Suite("Newline Escaping")
  internal struct NewlineEscaping {
    private let escaper = JSONEscaper()

    @Test("Newline is escaped to \\n")
    internal func newlineEscaped() {
      let input = "Line 1\nLine 2"
      let output = escaper.escape(input)
      #expect(output == "Line 1\\nLine 2")
    }

    @Test("Multiple newlines")
    internal func multipleNewlines() {
      let input = "A\nB\nC"
      let output = escaper.escape(input)
      #expect(output == "A\\nB\\nC")
    }

    @Test("Consecutive newlines")
    internal func consecutiveNewlines() {
      let input = "Text\n\nMore"
      let output = escaper.escape(input)
      #expect(output == "Text\\n\\nMore")
    }
  }
}
