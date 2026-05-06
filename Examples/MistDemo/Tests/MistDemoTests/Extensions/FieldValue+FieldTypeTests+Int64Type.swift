// swiftlint:disable file_name
//
//  FieldValue+FieldTypeTests+Int64Type.swift
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
  @Suite("Int64 Type")
  internal struct Int64Type {
    @Test("Initialize FieldValue.int64 from Int64 value")
    internal func initializeInt64FromInt64Value() {
      let fieldValue = FieldValue(value: Int64(42), fieldType: .int64)

      #expect(fieldValue != nil)
      if case .int64(let value) = fieldValue {
        #expect(value == 42)
      } else {
        Issue.record("Expected .int64 case")
      }
    }

    @Test("Initialize FieldValue.int64 from Int value")
    internal func initializeInt64FromIntValue() {
      let fieldValue = FieldValue(value: 42 as Int, fieldType: .int64)

      #expect(fieldValue != nil)
      if case .int64(let value) = fieldValue {
        #expect(value == 42)
      } else {
        Issue.record("Expected .int64 case")
      }
    }

    @Test("Initialize FieldValue.int64 from negative Int64")
    internal func initializeInt64FromNegativeInt64() {
      let fieldValue = FieldValue(value: Int64(-123), fieldType: .int64)

      #expect(fieldValue != nil)
      if case .int64(let value) = fieldValue {
        #expect(value == -123)
      } else {
        Issue.record("Expected .int64 case")
      }
    }

    @Test("Initialize FieldValue.int64 from zero")
    internal func initializeInt64FromZero() {
      let fieldValue = FieldValue(value: Int64(0), fieldType: .int64)

      #expect(fieldValue != nil)
      if case .int64(let value) = fieldValue {
        #expect(value == 0)
      } else {
        Issue.record("Expected .int64 case")
      }
    }

    @Test(
      "Initialize FieldValue.int64 from Int64.max",
      .enabled(
        if: Int.bitWidth >= 64,
        "FieldValue.int64 stores Int; Int64.max overflows native Int on 32-bit platforms (wasm32)"
      )
    )
    internal func initializeInt64FromMaxValue() {
      let fieldValue = FieldValue(value: Int64.max, fieldType: .int64)

      #expect(fieldValue != nil)
      if case .int64(let value) = fieldValue {
        #expect(value == Int(Int64.max))
      } else {
        Issue.record("Expected .int64 case")
      }
    }

    @Test("Int64 type with non-numeric value returns nil")
    internal func int64TypeWithNonNumericValueReturnsNil() {
      let fieldValue = FieldValue(value: "not a number" as String, fieldType: .int64)

      #expect(fieldValue == nil)
    }
  }
}
