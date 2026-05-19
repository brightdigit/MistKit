//
//  TableEscaperTests+CarriageReturnConversion.swift
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
  @Suite("Carriage Return Conversion")
  internal struct CarriageReturnConversion {
    private let escaper = TableEscaper()

    @Test("Carriage return is converted to space")
    internal func carriageReturnToSpace() {
      let input = "Before\rAfter"
      let output = escaper.escape(input)
      #expect(output == "Before After")
    }

    @Test("CRLF is converted to spaces")
    internal func crlfToSpaces() {
      let input = "Windows\r\nLine"
      let output = escaper.escape(input)
      #expect(output == "Windows  Line")
    }

    @Test("Multiple carriage returns")
    internal func multipleCarriageReturns() {
      let input = "A\rB\rC"
      let output = escaper.escape(input)
      #expect(output == "A B C")
    }
  }
}
