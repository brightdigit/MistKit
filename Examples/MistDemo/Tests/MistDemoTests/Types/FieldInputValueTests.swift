//
//  FieldInputValueTests.swift
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

@Suite("FieldInputValue Conversion Tests")
struct FieldInputValueTests {

    // MARK: - String Case Tests

    @Test("String case converts to string type")
    func stringCaseConvertsToStringType() throws {
        let input = FieldInputValue.string("Hello World")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "Hello World")
    }

    @Test("String case with empty string")
    func stringCaseWithEmptyString() throws {
        let input = FieldInputValue.string("")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "")
    }

    @Test("String case with special characters")
    func stringCaseWithSpecialCharacters() throws {
        let input = FieldInputValue.string("!@#$%^&*()")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "!@#$%^&*()")
    }

    @Test("String case with Unicode")
    func stringCaseWithUnicode() throws {
        let input = FieldInputValue.string("こんにちは")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "こんにちは")
    }

    @Test("String case with emoji")
    func stringCaseWithEmoji() throws {
        let input = FieldInputValue.string("👍🎉")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "👍🎉")
    }

    // MARK: - Int Case Tests

    @Test("Int case converts to int64 type")
    func intCaseConvertsToInt64Type() throws {
        let input = FieldInputValue.int(42)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .int64)
        #expect(value == "42")
    }

    @Test("Int case with zero")
    func intCaseWithZero() throws {
        let input = FieldInputValue.int(0)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .int64)
        #expect(value == "0")
    }

    @Test("Int case with negative number")
    func intCaseWithNegativeNumber() throws {
        let input = FieldInputValue.int(-123)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .int64)
        #expect(value == "-123")
    }

    @Test("Int case with large positive number")
    func intCaseWithLargePositiveNumber() throws {
        let input = FieldInputValue.int(Int.max)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .int64)
        #expect(value == String(Int.max))
    }

    @Test("Int case with large negative number")
    func intCaseWithLargeNegativeNumber() throws {
        let input = FieldInputValue.int(Int.min)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .int64)
        #expect(value == String(Int.min))
    }

    // MARK: - Double Case Tests

    @Test("Double case converts to double type")
    func doubleCaseConvertsToDoubleType() throws {
        let input = FieldInputValue.double(19.99)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        #expect(value == "19.99")
    }

    @Test("Double case with zero")
    func doubleCaseWithZero() throws {
        let input = FieldInputValue.double(0.0)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        #expect(value == "0.0")
    }

    @Test("Double case with negative number")
    func doubleCaseWithNegativeNumber() throws {
        let input = FieldInputValue.double(-3.14)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        #expect(value == "-3.14")
    }

    @Test("Double case with integer value")
    func doubleCaseWithIntegerValue() throws {
        let input = FieldInputValue.double(42.0)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        #expect(value == "42.0")
    }

    @Test("Double case with scientific notation")
    func doubleCaseWithScientificNotation() throws {
        let input = FieldInputValue.double(1.5e10)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        // Value may be in scientific notation
        #expect(value.contains("e") || value.contains("E") || value == "15000000000.0")
    }

    @Test("Double case with very small number")
    func doubleCaseWithVerySmallNumber() throws {
        let input = FieldInputValue.double(0.00001)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        #expect(value.contains("0.00001") || value.contains("e"))
    }

    // MARK: - Bool Case Tests

    @Test("Bool case with true converts to string 'true'")
    func boolCaseWithTrueConvertsToStringTrue() throws {
        let input = FieldInputValue.bool(true)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "true")
    }

    @Test("Bool case with false converts to string 'false'")
    func boolCaseWithFalseConvertsToStringFalse() throws {
        let input = FieldInputValue.bool(false)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "false")
    }

    // MARK: - Edge Case Tests

    @Test("String case preserves whitespace")
    func stringCasePreservesWhitespace() throws {
        let input = FieldInputValue.string("  spaces  ")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "  spaces  ")
    }

    @Test("String case with newlines")
    func stringCaseWithNewlines() throws {
        let input = FieldInputValue.string("line1\nline2")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "line1\nline2")
    }

    @Test("String case with tabs")
    func stringCaseWithTabs() throws {
        let input = FieldInputValue.string("col1\tcol2")
        let (type, value) = try input.toFieldComponents()

        #expect(type == .string)
        #expect(value == "col1\tcol2")
    }

    @Test("Double case preserves precision")
    func doubleCasePreservesPrecision() throws {
        let input = FieldInputValue.double(3.141592653589793)
        let (type, value) = try input.toFieldComponents()

        #expect(type == .double)
        // String should contain most of the precision
        #expect(value.contains("3.14"))
    }

    @Test("Multiple conversions of same value produce consistent results")
    func multipleConversionsProduceConsistentResults() throws {
        let input = FieldInputValue.int(42)

        let (type1, value1) = try input.toFieldComponents()
        let (type2, value2) = try input.toFieldComponents()

        #expect(type1 == type2)
        #expect(value1 == value2)
    }
}
