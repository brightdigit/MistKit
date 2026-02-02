//
//  FieldTests.swift
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

@Suite("Field Parsing Tests")
struct FieldTests {

    // MARK: - Basic Parsing Tests

    @Test("Parse basic string field")
    func parseBasicStringField() throws {
        let field = try Field(parsing: "title:string:Hello World")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "Hello World")
    }

    @Test("Parse int64 field")
    func parseInt64Field() throws {
        let field = try Field(parsing: "count:int64:42")

        #expect(field.name == "count")
        #expect(field.type == .int64)
        #expect(field.value == "42")
    }

    @Test("Parse double field")
    func parseDoubleField() throws {
        let field = try Field(parsing: "price:double:19.99")

        #expect(field.name == "price")
        #expect(field.type == .double)
        #expect(field.value == "19.99")
    }

    @Test("Parse timestamp field")
    func parseTimestampField() throws {
        let field = try Field(parsing: "createdAt:timestamp:2024-01-15T10:30:00Z")

        #expect(field.name == "createdAt")
        #expect(field.type == .timestamp)
        #expect(field.value == "2024-01-15T10:30:00Z")
    }

    // MARK: - Colon Handling Tests

    @Test("Parse field with colons in value (URL)")
    func parseFieldWithColonsInURL() throws {
        let field = try Field(parsing: "url:string:https://example.com:8080/path")

        #expect(field.name == "url")
        #expect(field.type == .string)
        #expect(field.value == "https://example.com:8080/path")
    }

    @Test("Parse field with colons in value (time)")
    func parseFieldWithColonsInTime() throws {
        let field = try Field(parsing: "time:string:10:30:45")

        #expect(field.name == "time")
        #expect(field.type == .string)
        #expect(field.value == "10:30:45")
    }

    @Test("Parse field with multiple colons in value")
    func parseFieldWithMultipleColons() throws {
        let field = try Field(parsing: "data:string:a:b:c:d:e")

        #expect(field.name == "data")
        #expect(field.type == .string)
        #expect(field.value == "a:b:c:d:e")
    }

    // MARK: - Whitespace Handling Tests

    @Test("Parse field with leading/trailing whitespace in name")
    func parseFieldWithWhitespaceInName() throws {
        let field = try Field(parsing: "  title  :string:value")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "value")
    }

    @Test("Parse field with leading/trailing whitespace in type")
    func parseFieldWithWhitespaceInType() throws {
        let field = try Field(parsing: "title:  string  :value")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "value")
    }

    @Test("Parse field preserving whitespace in value")
    func parseFieldPreservingWhitespaceInValue() throws {
        let field = try Field(parsing: "title:string:  Hello World  ")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "  Hello World  ")
    }

    @Test("Parse field with only whitespace in value")
    func parseFieldWithOnlyWhitespaceInValue() throws {
        let field = try Field(parsing: "title:string:   ")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "   ")
    }

    // MARK: - Edge Cases

    @Test("Parse field with empty value")
    func parseFieldWithEmptyValue() throws {
        let field = try Field(parsing: "title:string:")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "")
    }

    @Test("Parse field with Unicode in value")
    func parseFieldWithUnicode() throws {
        let field = try Field(parsing: "message:string:こんにちは世界")

        #expect(field.name == "message")
        #expect(field.type == .string)
        #expect(field.value == "こんにちは世界")
    }

    @Test("Parse field with emoji in value")
    func parseFieldWithEmoji() throws {
        let field = try Field(parsing: "reaction:string:👍🎉🚀")

        #expect(field.name == "reaction")
        #expect(field.type == .string)
        #expect(field.value == "👍🎉🚀")
    }

    @Test("Parse field with special characters in value")
    func parseFieldWithSpecialCharacters() throws {
        let field = try Field(parsing: "data:string:!@#$%^&*()_+-=[]{}|;'\"<>,.?/~`")

        #expect(field.name == "data")
        #expect(field.type == .string)
        #expect(field.value == "!@#$%^&*()_+-=[]{}|;'\"<>,.?/~`")
    }

    @Test("Parse field with newline in value")
    func parseFieldWithNewlineInValue() throws {
        let field = try Field(parsing: "text:string:line1\nline2")

        #expect(field.name == "text")
        #expect(field.type == .string)
        #expect(field.value == "line1\nline2")
    }

    @Test("Parse field with tab in value")
    func parseFieldWithTabInValue() throws {
        let field = try Field(parsing: "text:string:col1\tcol2")

        #expect(field.name == "text")
        #expect(field.type == .string)
        #expect(field.value == "col1\tcol2")
    }

    // MARK: - Case Sensitivity Tests

    @Test("Parse field with uppercase type (normalized to lowercase)")
    func parseFieldWithUppercaseType() throws {
        let field = try Field(parsing: "title:STRING:value")

        #expect(field.name == "title")
        #expect(field.type == .string)
        #expect(field.value == "value")
    }

    @Test("Parse field with mixed case type")
    func parseFieldWithMixedCaseType() throws {
        let field = try Field(parsing: "count:InT64:42")

        #expect(field.name == "count")
        #expect(field.type == .int64)
        #expect(field.value == "42")
    }

    // MARK: - Error Cases

    @Test("Parse field with empty name throws error")
    func parseFieldWithEmptyName() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: ":string:value")
        }
    }

    @Test("Parse field with whitespace-only name throws error")
    func parseFieldWithWhitespaceOnlyName() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: "   :string:value")
        }
    }

    @Test("Parse field with unknown type throws error")
    func parseFieldWithUnknownType() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: "title:unknown:value")
        }
    }

    @Test("Parse field with invalid format (too few parts)")
    func parseFieldWithTooFewParts() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: "title:string")
        }
    }

    @Test("Parse field with invalid format (one part)")
    func parseFieldWithOnePart() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: "title")
        }
    }

    @Test("Parse field with invalid format (empty string)")
    func parseFieldWithEmptyString() {
        #expect(throws: FieldParsingError.self) {
            try Field(parsing: "")
        }
    }

    // MARK: - parseMultiple Tests

    @Test("Parse multiple valid fields")
    func parseMultipleValidFields() throws {
        let inputs = [
            "title:string:Hello",
            "count:int64:42",
            "price:double:19.99"
        ]

        let fields = try Field.parseMultiple(inputs)

        #expect(fields.count == 3)
        #expect(fields[0].name == "title")
        #expect(fields[1].name == "count")
        #expect(fields[2].name == "price")
    }

    @Test("Parse multiple fields with empty array")
    func parseMultipleFieldsWithEmptyArray() throws {
        let fields = try Field.parseMultiple([])

        #expect(fields.isEmpty)
    }

    @Test("Parse multiple fields throws on first invalid")
    func parseMultipleFieldsThrowsOnInvalid() {
        let inputs = [
            "title:string:Hello",
            "invalid",
            "price:double:19.99"
        ]

        #expect(throws: FieldParsingError.self) {
            try Field.parseMultiple(inputs)
        }
    }
}
