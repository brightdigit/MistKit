//
//  YAMLEscaperTests+NumericString.swift
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

extension YAMLEscaperTests {
  @Suite("Numeric String")
  internal struct NumericString {
    private let escaper = YAMLEscaper()

    @Test("Integer string is quoted")
    internal func integerStringIsQuoted() {
      let input = "123"
      let output = escaper.escape(input)
      #expect(output == "\"123\"")
    }

    @Test("Negative integer string is quoted")
    internal func negativeIntegerIsQuoted() {
      let input = "-456"
      let output = escaper.escape(input)
      #expect(output == "\"-456\"")
    }

    @Test("Float string is quoted")
    internal func floatStringIsQuoted() {
      let input = "3.14"
      let output = escaper.escape(input)
      #expect(output == "\"3.14\"")
    }

    @Test("Scientific notation string is quoted")
    internal func scientificNotationIsQuoted() {
      let input = "1.23e10"
      let output = escaper.escape(input)
      #expect(output == "\"1.23e10\"")
    }

    @Test("Zero string is quoted")
    internal func zeroIsQuoted() {
      let input = "0"
      let output = escaper.escape(input)
      #expect(output == "\"0\"")
    }
  }
}
