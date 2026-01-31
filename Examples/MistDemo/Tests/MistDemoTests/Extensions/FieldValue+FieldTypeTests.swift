//
//  FieldValue+FieldTypeTests.swift
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
import MistKit
@testable import MistDemo

@Suite("FieldValue+FieldType Initialization Tests")
struct FieldValueFieldTypeTests {

    // MARK: - String Type Tests

    @Test("Initialize FieldValue.string from String value and string type")
    func initializeStringFromStringValue() {
        let fieldValue = FieldValue(value: "Hello World" as String, fieldType: .string)

        #expect(fieldValue != nil)
        if case .string(let value) = fieldValue {
            #expect(value == "Hello World")
        } else {
            Issue.record("Expected .string case")
        }
    }

    @Test("Initialize FieldValue.string from empty String")
    func initializeStringFromEmptyString() {
        let fieldValue = FieldValue(value: "" as String, fieldType: .string)

        #expect(fieldValue != nil)
        if case .string(let value) = fieldValue {
            #expect(value == "")
        } else {
            Issue.record("Expected .string case")
        }
    }

    @Test("String type with non-String value returns nil")
    func stringTypeWithNonStringValueReturnsNil() {
        let fieldValue = FieldValue(value: 42 as Int, fieldType: .string)

        #expect(fieldValue == nil)
    }

    // MARK: - Int64 Type Tests

    @Test("Initialize FieldValue.int64 from Int64 value")
    func initializeInt64FromInt64Value() {
        let fieldValue = FieldValue(value: Int64(42), fieldType: .int64)

        #expect(fieldValue != nil)
        if case .int64(let value) = fieldValue {
            #expect(value == 42)
        } else {
            Issue.record("Expected .int64 case")
        }
    }

    @Test("Initialize FieldValue.int64 from Int value")
    func initializeInt64FromIntValue() {
        let fieldValue = FieldValue(value: 42 as Int, fieldType: .int64)

        #expect(fieldValue != nil)
        if case .int64(let value) = fieldValue {
            #expect(value == 42)
        } else {
            Issue.record("Expected .int64 case")
        }
    }

    @Test("Initialize FieldValue.int64 from negative Int64")
    func initializeInt64FromNegativeInt64() {
        let fieldValue = FieldValue(value: Int64(-123), fieldType: .int64)

        #expect(fieldValue != nil)
        if case .int64(let value) = fieldValue {
            #expect(value == -123)
        } else {
            Issue.record("Expected .int64 case")
        }
    }

    @Test("Initialize FieldValue.int64 from zero")
    func initializeInt64FromZero() {
        let fieldValue = FieldValue(value: Int64(0), fieldType: .int64)

        #expect(fieldValue != nil)
        if case .int64(let value) = fieldValue {
            #expect(value == 0)
        } else {
            Issue.record("Expected .int64 case")
        }
    }

    @Test("Initialize FieldValue.int64 from Int64.max")
    func initializeInt64FromMaxValue() {
        let fieldValue = FieldValue(value: Int64.max, fieldType: .int64)

        #expect(fieldValue != nil)
        if case .int64(let value) = fieldValue {
            #expect(value == Int(Int64.max))
        } else {
            Issue.record("Expected .int64 case")
        }
    }

    @Test("Int64 type with non-numeric value returns nil")
    func int64TypeWithNonNumericValueReturnsNil() {
        let fieldValue = FieldValue(value: "not a number" as String, fieldType: .int64)

        #expect(fieldValue == nil)
    }

    // MARK: - Double Type Tests

    @Test("Initialize FieldValue.double from Double value")
    func initializeDoubleFromDoubleValue() {
        let fieldValue = FieldValue(value: 19.99 as Double, fieldType: .double)

        #expect(fieldValue != nil)
        if case .double(let value) = fieldValue {
            #expect(value == 19.99)
        } else {
            Issue.record("Expected .double case")
        }
    }

    @Test("Initialize FieldValue.double from negative Double")
    func initializeDoubleFromNegativeDouble() {
        let fieldValue = FieldValue(value: -3.14 as Double, fieldType: .double)

        #expect(fieldValue != nil)
        if case .double(let value) = fieldValue {
            #expect(value == -3.14)
        } else {
            Issue.record("Expected .double case")
        }
    }

    @Test("Initialize FieldValue.double from zero")
    func initializeDoubleFromZero() {
        let fieldValue = FieldValue(value: 0.0 as Double, fieldType: .double)

        #expect(fieldValue != nil)
        if case .double(let value) = fieldValue {
            #expect(value == 0.0)
        } else {
            Issue.record("Expected .double case")
        }
    }

    @Test("Initialize FieldValue.double from integer Double")
    func initializeDoubleFromIntegerDouble() {
        let fieldValue = FieldValue(value: 42.0 as Double, fieldType: .double)

        #expect(fieldValue != nil)
        if case .double(let value) = fieldValue {
            #expect(value == 42.0)
        } else {
            Issue.record("Expected .double case")
        }
    }

    @Test("Double type with non-Double value returns nil")
    func doubleTypeWithNonDoubleValueReturnsNil() {
        let fieldValue = FieldValue(value: "not a number" as String, fieldType: .double)

        #expect(fieldValue == nil)
    }

    @Test("Double type with Int value returns nil")
    func doubleTypeWithIntValueReturnsNil() {
        let fieldValue = FieldValue(value: 42 as Int, fieldType: .double)

        #expect(fieldValue == nil)
    }

    // MARK: - Timestamp/Date Type Tests

    @Test("Initialize FieldValue.date from Date value and timestamp type")
    func initializeDateFromDateValue() {
        let date = Date(timeIntervalSince1970: 1705315800)
        let fieldValue = FieldValue(value: date, fieldType: .timestamp)

        #expect(fieldValue != nil)
        if case .date(let value) = fieldValue {
            #expect(value.timeIntervalSince1970 == 1705315800)
        } else {
            Issue.record("Expected .date case")
        }
    }

    @Test("Initialize FieldValue.date from epoch date")
    func initializeDateFromEpochDate() {
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
    func initializeDateFromCurrentDate() {
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
    func timestampTypeWithNonDateValueReturnsNil() {
        let fieldValue = FieldValue(value: "2024-01-15" as String, fieldType: .timestamp)

        #expect(fieldValue == nil)
    }

    @Test("Timestamp type with Int value returns nil")
    func timestampTypeWithIntValueReturnsNil() {
        let fieldValue = FieldValue(value: 1705315800 as Int, fieldType: .timestamp)

        #expect(fieldValue == nil)
    }

    // MARK: - Bytes Type Tests

    @Test("Initialize FieldValue.bytes from String value and bytes type")
    func initializeBytesFromStringValue() {
        let fieldValue = FieldValue(value: "base64data" as String, fieldType: .bytes)

        #expect(fieldValue != nil)
        if case .bytes(let value) = fieldValue {
            #expect(value == "base64data")
        } else {
            Issue.record("Expected .bytes case")
        }
    }

    @Test("Bytes type with non-String value returns nil")
    func bytesTypeWithNonStringValueReturnsNil() {
        let fieldValue = FieldValue(value: 42 as Int, fieldType: .bytes)

        #expect(fieldValue == nil)
    }

    // MARK: - Unsupported Type Tests

    @Test("Asset type returns nil")
    func assetTypeReturnsNil() {
        let fieldValue = FieldValue(value: "anything" as String, fieldType: .asset)

        #expect(fieldValue == nil)
    }

    @Test("Location type returns nil")
    func locationTypeReturnsNil() {
        let fieldValue = FieldValue(value: "anything" as String, fieldType: .location)

        #expect(fieldValue == nil)
    }

    @Test("Reference type returns nil")
    func referenceTypeReturnsNil() {
        let fieldValue = FieldValue(value: "anything" as String, fieldType: .reference)

        #expect(fieldValue == nil)
    }

    // MARK: - Invalid Type Conversion Tests

    @Test("Wrong type conversion returns nil (String as Int64)")
    func wrongTypeConversionStringAsInt64() {
        let fieldValue = FieldValue(value: "42" as String, fieldType: .int64)

        #expect(fieldValue == nil)
    }

    @Test("Wrong type conversion returns nil (Int as String)")
    func wrongTypeConversionIntAsString() {
        let fieldValue = FieldValue(value: 42 as Int, fieldType: .string)

        #expect(fieldValue == nil)
    }

    @Test("Wrong type conversion returns nil (Double as Int64)")
    func wrongTypeConversionDoubleAsInt64() {
        let fieldValue = FieldValue(value: 19.99 as Double, fieldType: .int64)

        #expect(fieldValue == nil)
    }
}
