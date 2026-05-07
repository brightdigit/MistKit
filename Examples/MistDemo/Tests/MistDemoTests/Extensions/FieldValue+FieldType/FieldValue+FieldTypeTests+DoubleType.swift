//
//  FieldValue+FieldTypeTests+DoubleType.swift
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
  @Suite("Double Type")
  internal struct DoubleType {
    @Test("Initialize FieldValue.double from Double value")
    internal func initializeDoubleFromDoubleValue() {
      let fieldValue = FieldValue(value: 19.99 as Double, fieldType: .double)

      #expect(fieldValue != nil)
      if case .double(let value) = fieldValue {
        #expect(value == 19.99)
      } else {
        Issue.record("Expected .double case")
      }
    }

    @Test("Initialize FieldValue.double from negative Double")
    internal func initializeDoubleFromNegativeDouble() {
      let fieldValue = FieldValue(value: -3.14 as Double, fieldType: .double)

      #expect(fieldValue != nil)
      if case .double(let value) = fieldValue {
        #expect(value == -3.14)
      } else {
        Issue.record("Expected .double case")
      }
    }

    @Test("Initialize FieldValue.double from zero")
    internal func initializeDoubleFromZero() {
      let fieldValue = FieldValue(value: 0.0 as Double, fieldType: .double)

      #expect(fieldValue != nil)
      if case .double(let value) = fieldValue {
        #expect(value == 0.0)
      } else {
        Issue.record("Expected .double case")
      }
    }

    @Test("Initialize FieldValue.double from integer Double")
    internal func initializeDoubleFromIntegerDouble() {
      let fieldValue = FieldValue(value: 42.0 as Double, fieldType: .double)

      #expect(fieldValue != nil)
      if case .double(let value) = fieldValue {
        #expect(value == 42.0)
      } else {
        Issue.record("Expected .double case")
      }
    }

    @Test("Double type with non-Double value returns nil")
    internal func doubleTypeWithNonDoubleValueReturnsNil() {
      let fieldValue = FieldValue(value: "not a number" as String, fieldType: .double)

      #expect(fieldValue == nil)
    }

    @Test("Double type with Int value returns nil")
    internal func doubleTypeWithIntValueReturnsNil() {
      let fieldValue = FieldValue(value: 42 as Int, fieldType: .double)

      #expect(fieldValue == nil)
    }
  }
}
