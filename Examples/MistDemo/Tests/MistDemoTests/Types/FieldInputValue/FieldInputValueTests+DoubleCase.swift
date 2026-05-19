//
//  FieldInputValueTests+DoubleCase.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

extension FieldInputValueTests {
  @Suite("Double Case")
  internal struct DoubleCase {
    @Test("Double case converts to double type")
    internal func doubleCaseConvertsToDoubleType() throws {
      let input = FieldInputValue.double(19.99)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      #expect(value == "19.99")
    }

    @Test("Double case with zero")
    internal func doubleCaseWithZero() throws {
      let input = FieldInputValue.double(0.0)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      #expect(value == "0.0")
    }

    @Test("Double case with negative number")
    internal func doubleCaseWithNegativeNumber() throws {
      let input = FieldInputValue.double(-3.14)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      #expect(value == "-3.14")
    }

    @Test("Double case with integer value")
    internal func doubleCaseWithIntegerValue() throws {
      let input = FieldInputValue.double(42.0)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      #expect(value == "42.0")
    }

    @Test("Double case with scientific notation")
    internal func doubleCaseWithScientificNotation() throws {
      let input = FieldInputValue.double(1.5e10)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      // Value may be in scientific notation
      #expect(value.contains("e") || value.contains("E") || value == "15000000000.0")
    }

    @Test("Double case with very small number")
    internal func doubleCaseWithVerySmallNumber() throws {
      let input = FieldInputValue.double(0.00001)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      #expect(value.contains("0.00001") || value.contains("e"))
    }
  }
}
