//
//  FieldTypeTests+DoubleConversion.swift
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

extension FieldTypeTests {
  @Suite("Double Conversion")
  internal struct DoubleConversion {
    @Test("Convert valid positive double")
    internal func convertValidPositiveDouble() throws {
      let value = try FieldType.double.convertValue("19.99")

      #expect(value as? Double == 19.99)
    }

    @Test("Convert valid negative double")
    internal func convertValidNegativeDouble() throws {
      let value = try FieldType.double.convertValue("-3.14")

      #expect(value as? Double == -3.14)
    }

    @Test("Convert double zero")
    internal func convertDoubleZero() throws {
      let value = try FieldType.double.convertValue("0.0")

      #expect(value as? Double == 0.0)
    }

    @Test("Convert double integer value")
    internal func convertDoubleIntegerValue() throws {
      let value = try FieldType.double.convertValue("42")

      #expect(value as? Double == 42.0)
    }

    @Test("Convert double scientific notation")
    internal func convertDoubleScientificNotation() throws {
      let value = try FieldType.double.convertValue("1.5e10")

      #expect(value as? Double == 1.5e10)
    }

    @Test("Convert double negative scientific notation")
    internal func convertDoubleNegativeScientificNotation() throws {
      let value = try FieldType.double.convertValue("3.14e-5")

      #expect(value as? Double == 3.14e-5)
    }

    @Test("Convert invalid double (non-numeric) throws error")
    internal func convertInvalidDoubleNonNumeric() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.double.convertValue("not a number")
      }
    }

    @Test("Convert invalid double (empty) throws error")
    internal func convertInvalidDoubleEmpty() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.double.convertValue("")
      }
    }
  }
}
