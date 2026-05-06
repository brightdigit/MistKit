//
//  YAMLEscaperTests+MultiLineString.swift
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
  @Suite("Multi-line String (Block Scalar)")
  internal struct MultiLineString {
    private let escaper = YAMLEscaper()

    @Test("Multi-line string uses block scalar")
    internal func multiLineUsesBlockScalar() {
      let input = "Line 1\nLine 2\nLine 3"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
      #expect(output.contains("Line 1"))
      #expect(output.contains("Line 2"))
      #expect(output.contains("Line 3"))
    }

    @Test("Two-line string uses block scalar")
    internal func twoLineUsesBlockScalar() {
      let input = "First\nSecond"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|\n"))
    }

    @Test("String with empty line in middle")
    internal func multiLineWithEmptyLine() {
      let input = "Before\n\nAfter"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
      #expect(output.contains("Before"))
      #expect(output.contains("After"))
    }

    @Test("Multi-line string preserves indentation context")
    internal func multiLinePreservesContent() {
      let input = "Line 1\nLine 2"
      let output = escaper.escape(input)
      #expect(output.hasPrefix("|"))
      // Block scalar should have indented lines
      #expect(output.contains("    Line 1"))
      #expect(output.contains("    Line 2"))
    }
  }
}
