//
//  FieldValue+FieldTypeTests+UnsupportedType.swift
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
  @Suite("Unsupported Type")
  internal struct UnsupportedType {
    @Test("Asset type returns asset FieldValue")
    internal func assetTypeReturnsNil() {
      let fieldValue = FieldValue(value: "anything" as String, fieldType: .asset)

      #expect(fieldValue != nil)
      if case .asset(let asset) = fieldValue {
        #expect(asset.downloadURL == "anything")
      } else {
        Issue.record("Expected .asset case")
      }
    }

    @Test("Location type returns nil")
    internal func locationTypeReturnsNil() {
      let fieldValue = FieldValue(value: "anything" as String, fieldType: .location)

      #expect(fieldValue == nil)
    }

    @Test("Reference type returns nil")
    internal func referenceTypeReturnsNil() {
      let fieldValue = FieldValue(value: "anything" as String, fieldType: .reference)

      #expect(fieldValue == nil)
    }
  }
}
