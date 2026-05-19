//
//  FieldValue+FieldTypeTests+TimestampDateType.swift
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
  @Suite("Timestamp/Date Type")
  internal struct TimestampDateType {
    @Test("Initialize FieldValue.date from Date value and timestamp type")
    internal func initializeDateFromDateValue() {
      let date = Date(timeIntervalSince1970: 1_705_315_800)
      let fieldValue = FieldValue(value: date, fieldType: .timestamp)

      #expect(fieldValue != nil)
      if case .date(let value) = fieldValue {
        #expect(value.timeIntervalSince1970 == 1_705_315_800)
      } else {
        Issue.record("Expected .date case")
      }
    }

    @Test("Initialize FieldValue.date from epoch date")
    internal func initializeDateFromEpochDate() {
      let date = Date(timeIntervalSince1970: 0)
      let fieldValue = FieldValue(value: date, fieldType: .timestamp)

      #expect(fieldValue != nil)
      if case .date(let value) = fieldValue {
        #expect(value.timeIntervalSince1970 == 0)
      } else {
        Issue.record("Expected .date case")
      }
    }

    @Test("Initialize FieldValue.date from current date")
    internal func initializeDateFromCurrentDate() {
      let date = Date()
      let fieldValue = FieldValue(value: date, fieldType: .timestamp)

      #expect(fieldValue != nil)
      if case .date(let value) = fieldValue {
        #expect(value.timeIntervalSince1970 == date.timeIntervalSince1970)
      } else {
        Issue.record("Expected .date case")
      }
    }

    @Test("Timestamp type with non-Date value returns nil")
    internal func timestampTypeWithNonDateValueReturnsNil() {
      let fieldValue = FieldValue(value: "2024-01-15" as String, fieldType: .timestamp)

      #expect(fieldValue == nil)
    }

    @Test("Timestamp type with Int value returns nil")
    internal func timestampTypeWithIntValueReturnsNil() {
      let fieldValue = FieldValue(value: 1_705_315_800 as Int, fieldType: .timestamp)

      #expect(fieldValue == nil)
    }
  }
}
