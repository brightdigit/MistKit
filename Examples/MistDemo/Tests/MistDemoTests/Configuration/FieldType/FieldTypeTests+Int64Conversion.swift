//
//  FieldTypeTests+Int64Conversion.swift
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
  @Suite("Int64 Conversion")
  internal struct Int64Conversion {
    @Test("Convert valid positive int64")
    internal func convertValidPositiveInt64() throws {
      let value = try FieldType.int64.convertValue("42")

      #expect(value as? Int64 == 42)
    }

    @Test("Convert valid negative int64")
    internal func convertValidNegativeInt64() throws {
      let value = try FieldType.int64.convertValue("-123")

      #expect(value as? Int64 == -123)
    }

    @Test("Convert int64 zero")
    internal func convertInt64Zero() throws {
      let value = try FieldType.int64.convertValue("0")

      #expect(value as? Int64 == 0)
    }

    @Test("Convert int64 maximum value")
    internal func convertInt64MaxValue() throws {
      let value = try FieldType.int64.convertValue("9223372036854775807")

      #expect(value as? Int64 == Int64.max)
    }

    @Test("Convert int64 minimum value")
    internal func convertInt64MinValue() throws {
      let value = try FieldType.int64.convertValue("-9223372036854775808")

      #expect(value as? Int64 == Int64.min)
    }

    @Test("Convert invalid int64 (non-numeric) throws error")
    internal func convertInvalidInt64NonNumeric() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.int64.convertValue("not a number")
      }
    }

    @Test("Convert invalid int64 (decimal) throws error")
    internal func convertInvalidInt64Decimal() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.int64.convertValue("42.5")
      }
    }

    @Test("Convert invalid int64 (empty) throws error")
    internal func convertInvalidInt64Empty() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.int64.convertValue("")
      }
    }
  }
}
