//
//  CSVEscaperTests+PlainString.swift
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
  @Suite("Plain String")
  internal struct PlainString {
    private let escaper = CSVEscaper()

    @Test("Plain string without special characters needs no escaping")
    internal func plainStringNoEscaping() {
      let input = "Hello World"
      let output = escaper.escape(input)
      #expect(output == "Hello World")
    }

    @Test("Simple alphanumeric string needs no escaping")
    internal func alphanumericNoEscaping() {
      let input = "Test123"
      let output = escaper.escape(input)
      #expect(output == "Test123")
    }

    @Test("String with spaces needs no escaping")
    internal func stringWithSpacesNoEscaping() {
      let input = "This is a test"
      let output = escaper.escape(input)
      #expect(output == "This is a test")
    }

    @Test("Empty string needs no escaping")
    internal func emptyStringNoEscaping() {
      let input = ""
      let output = escaper.escape(input)
      #expect(output.isEmpty)
    }
  }
}
