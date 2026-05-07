//
//  FieldTypeTests+TimestampConversion.swift
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
import Testing

@testable import MistDemoKit

extension FieldTypeTests {
  @Suite("Timestamp Conversion")
  internal struct TimestampConversion {
    @Test("Convert timestamp from ISO 8601 date")
    internal func convertTimestampFromISO8601() throws {
      let value = try FieldType.timestamp.convertValue("2024-01-15T10:30:00Z")

      #expect(value is Date)
      let date = value as? Date
      #expect(date != nil)
    }

    @Test("Convert timestamp from ISO 8601 with timezone")
    internal func convertTimestampFromISO8601WithTimezone() throws {
      let value = try FieldType.timestamp.convertValue("2024-01-15T10:30:00+05:00")

      #expect(value is Date)
    }

    @Test("Convert timestamp from Unix timestamp (integer)")
    internal func convertTimestampFromUnixInteger() throws {
      let value = try FieldType.timestamp.convertValue("1705315800")

      let date = value as? Date
      #expect(date?.timeIntervalSince1970 == 1_705_315_800.0)
    }

    @Test("Convert timestamp from Unix timestamp (decimal)")
    internal func convertTimestampFromUnixDecimal() throws {
      let value = try FieldType.timestamp.convertValue("1705315800.5")

      let date = value as? Date
      #expect(date?.timeIntervalSince1970 == 1_705_315_800.5)
    }

    @Test("Convert timestamp from zero (epoch)")
    internal func convertTimestampFromZero() throws {
      let value = try FieldType.timestamp.convertValue("0")

      let date = value as? Date
      #expect(date?.timeIntervalSince1970 == 0.0)
    }

    @Test("Convert invalid timestamp (non-date string) throws error")
    internal func convertInvalidTimestampNonDate() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.timestamp.convertValue("not a date")
      }
    }

    @Test("Convert invalid timestamp (empty) throws error")
    internal func convertInvalidTimestampEmpty() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.timestamp.convertValue("")
      }
    }

    @Test("Convert invalid timestamp (invalid ISO format) throws error")
    internal func convertInvalidTimestampInvalidISO() {
      #expect(throws: FieldParsingError.self) {
        try FieldType.timestamp.convertValue("2024-13-45T99:99:99Z")
      }
    }
  }
}
