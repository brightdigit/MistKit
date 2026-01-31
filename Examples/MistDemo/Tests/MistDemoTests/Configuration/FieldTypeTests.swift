//
//  FieldTypeTests.swift
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
@testable import MistDemo

@Suite("FieldType Conversion Tests")
struct FieldTypeTests {

    // MARK: - String Conversion Tests

    @Test("Convert string value (always succeeds)")
    func convertStringValue() throws {
        let value = try FieldType.string.convertValue("Hello World")

        #expect(value as? String == "Hello World")
    }

    @Test("Convert empty string value")
    func convertEmptyStringValue() throws {
        let value = try FieldType.string.convertValue("")

        #expect(value as? String == "")
    }

    @Test("Convert string with special characters")
    func convertStringWithSpecialCharacters() throws {
        let value = try FieldType.string.convertValue("!@#$%^&*()")

        #expect(value as? String == "!@#$%^&*()")
    }

    // MARK: - Int64 Conversion Tests

    @Test("Convert valid positive int64")
    func convertValidPositiveInt64() throws {
        let value = try FieldType.int64.convertValue("42")

        #expect(value as? Int64 == 42)
    }

    @Test("Convert valid negative int64")
    func convertValidNegativeInt64() throws {
        let value = try FieldType.int64.convertValue("-123")

        #expect(value as? Int64 == -123)
    }

    @Test("Convert int64 zero")
    func convertInt64Zero() throws {
        let value = try FieldType.int64.convertValue("0")

        #expect(value as? Int64 == 0)
    }

    @Test("Convert int64 maximum value")
    func convertInt64MaxValue() throws {
        let value = try FieldType.int64.convertValue("9223372036854775807")

        #expect(value as? Int64 == Int64.max)
    }

    @Test("Convert int64 minimum value")
    func convertInt64MinValue() throws {
        let value = try FieldType.int64.convertValue("-9223372036854775808")

        #expect(value as? Int64 == Int64.min)
    }

    @Test("Convert invalid int64 (non-numeric) throws error")
    func convertInvalidInt64NonNumeric() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.int64.convertValue("not a number")
        }
    }

    @Test("Convert invalid int64 (decimal) throws error")
    func convertInvalidInt64Decimal() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.int64.convertValue("42.5")
        }
    }

    @Test("Convert invalid int64 (empty) throws error")
    func convertInvalidInt64Empty() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.int64.convertValue("")
        }
    }

    // MARK: - Double Conversion Tests

    @Test("Convert valid positive double")
    func convertValidPositiveDouble() throws {
        let value = try FieldType.double.convertValue("19.99")

        #expect(value as? Double == 19.99)
    }

    @Test("Convert valid negative double")
    func convertValidNegativeDouble() throws {
        let value = try FieldType.double.convertValue("-3.14")

        #expect(value as? Double == -3.14)
    }

    @Test("Convert double zero")
    func convertDoubleZero() throws {
        let value = try FieldType.double.convertValue("0.0")

        #expect(value as? Double == 0.0)
    }

    @Test("Convert double integer value")
    func convertDoubleIntegerValue() throws {
        let value = try FieldType.double.convertValue("42")

        #expect(value as? Double == 42.0)
    }

    @Test("Convert double scientific notation")
    func convertDoubleScientificNotation() throws {
        let value = try FieldType.double.convertValue("1.5e10")

        #expect(value as? Double == 1.5e10)
    }

    @Test("Convert double negative scientific notation")
    func convertDoubleNegativeScientificNotation() throws {
        let value = try FieldType.double.convertValue("3.14e-5")

        #expect(value as? Double == 3.14e-5)
    }

    @Test("Convert invalid double (non-numeric) throws error")
    func convertInvalidDoubleNonNumeric() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.double.convertValue("not a number")
        }
    }

    @Test("Convert invalid double (empty) throws error")
    func convertInvalidDoubleEmpty() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.double.convertValue("")
        }
    }

    // MARK: - Timestamp Conversion Tests

    @Test("Convert timestamp from ISO 8601 date")
    func convertTimestampFromISO8601() throws {
        let value = try FieldType.timestamp.convertValue("2024-01-15T10:30:00Z")

        #expect(value is Date)
        let date = value as? Date
        #expect(date != nil)
    }

    @Test("Convert timestamp from ISO 8601 with timezone")
    func convertTimestampFromISO8601WithTimezone() throws {
        let value = try FieldType.timestamp.convertValue("2024-01-15T10:30:00+05:00")

        #expect(value is Date)
    }

    @Test("Convert timestamp from Unix timestamp (integer)")
    func convertTimestampFromUnixInteger() throws {
        let value = try FieldType.timestamp.convertValue("1705315800")

        let date = value as? Date
        #expect(date?.timeIntervalSince1970 == 1705315800.0)
    }

    @Test("Convert timestamp from Unix timestamp (decimal)")
    func convertTimestampFromUnixDecimal() throws {
        let value = try FieldType.timestamp.convertValue("1705315800.5")

        let date = value as? Date
        #expect(date?.timeIntervalSince1970 == 1705315800.5)
    }

    @Test("Convert timestamp from zero (epoch)")
    func convertTimestampFromZero() throws {
        let value = try FieldType.timestamp.convertValue("0")

        let date = value as? Date
        #expect(date?.timeIntervalSince1970 == 0.0)
    }

    @Test("Convert invalid timestamp (non-date string) throws error")
    func convertInvalidTimestampNonDate() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.timestamp.convertValue("not a date")
        }
    }

    @Test("Convert invalid timestamp (empty) throws error")
    func convertInvalidTimestampEmpty() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.timestamp.convertValue("")
        }
    }

    @Test("Convert invalid timestamp (invalid ISO format) throws error")
    func convertInvalidTimestampInvalidISO() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.timestamp.convertValue("2024-13-45T99:99:99Z")
        }
    }

    // MARK: - Unsupported Type Tests

    @Test("Convert asset type throws unsupported error")
    func convertAssetThrowsUnsupported() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.asset.convertValue("anything")
        }
    }

    @Test("Convert location type throws unsupported error")
    func convertLocationThrowsUnsupported() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.location.convertValue("anything")
        }
    }

    @Test("Convert reference type throws unsupported error")
    func convertReferenceThrowsUnsupported() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.reference.convertValue("anything")
        }
    }

    @Test("Convert bytes type throws unsupported error")
    func convertBytesThrowsUnsupported() {
        #expect(throws: FieldParsingError.self) {
            try FieldType.bytes.convertValue("anything")
        }
    }

    // MARK: - Enum Properties Tests

    @Test("FieldType has all expected cases")
    func fieldTypeAllCases() {
        let allCases = FieldType.allCases

        #expect(allCases.contains(.string))
        #expect(allCases.contains(.int64))
        #expect(allCases.contains(.double))
        #expect(allCases.contains(.timestamp))
        #expect(allCases.contains(.asset))
        #expect(allCases.contains(.location))
        #expect(allCases.contains(.reference))
        #expect(allCases.contains(.bytes))
        #expect(allCases.count == 8)
    }

    @Test("FieldType raw values are correct")
    func fieldTypeRawValues() {
        #expect(FieldType.string.rawValue == "string")
        #expect(FieldType.int64.rawValue == "int64")
        #expect(FieldType.double.rawValue == "double")
        #expect(FieldType.timestamp.rawValue == "timestamp")
        #expect(FieldType.asset.rawValue == "asset")
        #expect(FieldType.location.rawValue == "location")
        #expect(FieldType.reference.rawValue == "reference")
        #expect(FieldType.bytes.rawValue == "bytes")
    }

    @Test("FieldType can be initialized from raw value")
    func fieldTypeInitFromRawValue() {
        #expect(FieldType(rawValue: "string") == .string)
        #expect(FieldType(rawValue: "int64") == .int64)
        #expect(FieldType(rawValue: "double") == .double)
        #expect(FieldType(rawValue: "timestamp") == .timestamp)
    }

    @Test("FieldType returns nil for invalid raw value")
    func fieldTypeNilForInvalidRawValue() {
        #expect(FieldType(rawValue: "invalid") == nil)
        #expect(FieldType(rawValue: "STRING") == nil) // case-sensitive
        #expect(FieldType(rawValue: "") == nil)
    }
}
