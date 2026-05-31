//
//  FieldValue+FieldTypeTests+StringType.swift
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
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension FieldValueFieldTypeTests {
  @Suite("String Type")
  internal struct StringType {
    @Test("Initialize FieldValue.string from String value and string type")
    internal func initializeStringFromStringValue() {
      let fieldValue = FieldValue(value: "Hello World" as String, fieldType: .string)

      #expect(fieldValue != nil)
      if case .string(let value) = fieldValue {
        #expect(value == "Hello World")
      } else {
        Issue.record("Expected .string case")
      }
    }

    @Test("Initialize FieldValue.string from empty String")
    internal func initializeStringFromEmptyString() {
      let fieldValue = FieldValue(value: "" as String, fieldType: .string)

      #expect(fieldValue != nil)
      if case .string(let value) = fieldValue {
        #expect(value.isEmpty)
      } else {
        Issue.record("Expected .string case")
      }
    }

    @Test("String type with non-String value returns nil")
    internal func stringTypeWithNonStringValueReturnsNil() {
      let fieldValue = FieldValue(value: 42 as Int, fieldType: .string)

      #expect(fieldValue == nil)
    }
  }
}
