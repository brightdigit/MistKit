//
//  CSVEscaperTests+NewlineEscaping.swift
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

extension CSVEscaperTests {
  @Suite("Newline Escaping")
  internal struct NewlineEscaping {
    private let escaper = CSVEscaper()

    @Test("String with newline is escaped and quoted")
    internal func stringWithNewline() {
      let input = "Line 1\nLine 2"
      let output = escaper.escape(input)
      #expect(output == "\"Line 1\nLine 2\"")
    }

    @Test("String with carriage return is escaped")
    internal func stringWithCarriageReturn() {
      let input = "Before\rAfter"
      let output = escaper.escape(input)
      #expect(output == "\"Before\rAfter\"")
    }

    @Test("String with CRLF is escaped")
    internal func stringWithCRLF() {
      let input = "Windows\r\nLine"
      let output = escaper.escape(input)
      #expect(output == "\"Windows\r\nLine\"")
    }

    @Test("String with only newline")
    internal func onlyNewline() {
      let input = "\n"
      let output = escaper.escape(input)
      #expect(output == "\"\n\"")
    }
  }
}
