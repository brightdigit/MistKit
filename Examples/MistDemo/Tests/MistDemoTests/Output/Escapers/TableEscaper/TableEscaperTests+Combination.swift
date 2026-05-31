//
//  TableEscaperTests+Combination.swift
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
internal import Testing

@testable import MistDemoKit

extension TableEscaperTests {
  @Suite("Combination")
  internal struct Combination {
    private let escaper = TableEscaper()

    @Test("Newlines, tabs, and spaces together")
    internal func allWhitespaceTypes() {
      let input = "A\nB\tC D"
      let output = escaper.escape(input)
      #expect(output == "A B C D")
    }

    @Test("Complex multi-line with tabs")
    internal func complexMultiLine() {
      let input = "Line 1\n\tIndented\nLine 3"
      let output = escaper.escape(input)
      #expect(output == "Line 1  Indented Line 3")
    }

    @Test("Mixed whitespace with trimming")
    internal func mixedWithTrimming() {
      let input = "  \n Text \t  "
      let output = escaper.escape(input)
      #expect(output == "Text")
    }

    @Test("Internal spaces preserved")
    internal func internalSpacesPreserved() {
      let input = "Word1 Word2  Word3"
      let output = escaper.escape(input)
      #expect(output == "Word1 Word2  Word3")
    }
  }
}
