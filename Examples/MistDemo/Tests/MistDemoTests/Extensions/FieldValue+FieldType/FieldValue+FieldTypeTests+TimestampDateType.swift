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

  /// End-to-end check of MistDemo's timestamp request path: a `--type timestamp`
  /// field value goes `String → FieldType.convertValue → FieldValue.date →`
  /// CloudKit's millisecond wire representation. The individual steps are
  /// covered above; this asserts the composed pipeline emits the TIMESTAMP
  /// milliseconds CloudKit expects (the request side of issue #375/#376).
  @Suite("Timestamp Wire Round-Trip")
  internal struct TimestampWireRoundTrip {
    @Test("ISO 8601 timestamp field encodes to CloudKit milliseconds")
    internal func iso8601EncodesToMilliseconds() throws {
      let date = try #require(
        try FieldType.timestamp.convertValue("2024-01-15T10:30:00Z") as? Date
      )
      let fieldValue = try #require(FieldValue(value: date, fieldType: .timestamp))

      let data = try JSONEncoder().encode(fieldValue)
      let milliseconds = try JSONDecoder().decode(Double.self, from: data)

      // CloudKit encodes TIMESTAMP as milliseconds since the Unix epoch.
      #expect(milliseconds == date.timeIntervalSince1970 * 1_000)
    }

    @Test("Unix-epoch timestamp field encodes to CloudKit milliseconds")
    internal func epochEncodesToMilliseconds() throws {
      let date = try #require(
        try FieldType.timestamp.convertValue("1705315800") as? Date
      )
      let fieldValue = try #require(FieldValue(value: date, fieldType: .timestamp))

      let data = try JSONEncoder().encode(fieldValue)
      let milliseconds = try JSONDecoder().decode(Double.self, from: data)

      #if arch(wasm32)
        // On wasm32, Int is 32-bit; the Int product overflows at compile time,
        // so compute the expected milliseconds as a Double.
        #expect(milliseconds == 1_705_315_800.0 * 1_000)
      #else
        #expect(milliseconds == 1_705_315_800 * 1_000)
      #endif
    }
  }
}
