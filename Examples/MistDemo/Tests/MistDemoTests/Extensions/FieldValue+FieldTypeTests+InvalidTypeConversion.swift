// swiftlint:disable file_name
//
//  FieldValue+FieldTypeTests+InvalidTypeConversion.swift
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

import Foundation
import MistKit
import Testing

@testable import MistDemoKit

extension FieldValueFieldTypeTests {
  @Suite("Invalid Type Conversion")
  internal struct InvalidTypeConversion {
    @Test("Wrong type conversion returns nil (String as Int64)")
    internal func wrongTypeConversionStringAsInt64() {
      let fieldValue = FieldValue(value: "42" as String, fieldType: .int64)

      #expect(fieldValue == nil)
    }

    @Test("Wrong type conversion returns nil (Int as String)")
    internal func wrongTypeConversionIntAsString() {
      let fieldValue = FieldValue(value: 42 as Int, fieldType: .string)

      #expect(fieldValue == nil)
    }

    @Test("Wrong type conversion returns nil (Double as Int64)")
    internal func wrongTypeConversionDoubleAsInt64() {
      let fieldValue = FieldValue(value: 19.99 as Double, fieldType: .int64)

      #expect(fieldValue == nil)
    }
  }
}
