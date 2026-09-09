//
//  FieldValue+FieldTypeTests+BytesType.swift
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
  @Suite("Bytes Type")
  internal struct BytesType {
    @Test("Initialize FieldValue.bytes from valid base64 String value and bytes type")
    internal func initializeBytesFromStringValue() {
      let fieldValue = FieldValue(value: "aGVsbG8=" as String, fieldType: .bytes)

      #expect(fieldValue != nil)
      if case .bytes(let value) = fieldValue {
        #expect(value == Data("hello".utf8))
      } else {
        Issue.record("Expected .bytes case")
      }
    }

    @Test("Bytes type with malformed base64 returns nil")
    internal func bytesTypeWithMalformedBase64ReturnsNil() {
      let fieldValue = FieldValue(value: "not!valid!" as String, fieldType: .bytes)

      #expect(fieldValue == nil)
    }

    @Test("Bytes type with non-String value returns nil")
    internal func bytesTypeWithNonStringValueReturnsNil() {
      let fieldValue = FieldValue(value: 42 as Int, fieldType: .bytes)

      #expect(fieldValue == nil)
    }
  }
}
