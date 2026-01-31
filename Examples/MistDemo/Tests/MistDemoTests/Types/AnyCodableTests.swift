//
//  AnyCodableTests.swift
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

@Suite("AnyCodable Tests")
struct AnyCodableTests {

    // MARK: - String Decoding Tests

    @Test("Decode string value")
    func decodeString() throws {
        let json = "\"hello world\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? String == "hello world")
    }

    @Test("Decode empty string")
    func decodeEmptyString() throws {
        let json = "\"\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? String == "")
    }

    // MARK: - Integer Decoding Tests

    @Test("Decode positive integer")
    func decodePositiveInt() throws {
        let json = "42"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Int == 42)
    }

    @Test("Decode negative integer")
    func decodeNegativeInt() throws {
        let json = "-123"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Int == -123)
    }

    @Test("Decode zero")
    func decodeZero() throws {
        let json = "0"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Int == 0)
    }

    // MARK: - Double Decoding Tests

    @Test("Decode positive double")
    func decodePositiveDouble() throws {
        let json = "3.14"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Double == 3.14)
    }

    @Test("Decode negative double")
    func decodeNegativeDouble() throws {
        let json = "-2.5"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Double == -2.5)
    }

    @Test("Decode double with scientific notation")
    func decodeScientificNotation() throws {
        let json = "1.23e-4"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Double == 1.23e-4)
    }

    // MARK: - Boolean Decoding Tests

    @Test("Decode true")
    func decodeTrue() throws {
        let json = "true"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Bool == true)
    }

    @Test("Decode false")
    func decodeFalse() throws {
        let json = "false"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Bool == false)
    }

    // MARK: - Null Decoding Tests

    @Test("Decode null value")
    func decodeNull() throws {
        let json = "null"
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value is NSNull)
    }

    // MARK: - Encoding Tests

    @Test("Encode string value")
    func encodeString() throws {
        let anyCodable = AnyCodable(value: "test")
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "\"test\"")
    }

    @Test("Encode integer value")
    func encodeInteger() throws {
        let anyCodable = AnyCodable(value: 123)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "123")
    }

    @Test("Encode double value")
    func encodeDouble() throws {
        let anyCodable = AnyCodable(value: 3.14)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)!
        #expect(json.contains("3.14"))
    }

    @Test("Encode boolean value")
    func encodeBoolean() throws {
        let anyCodable = AnyCodable(value: true)
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "true")
    }

    @Test("Encode null value")
    func encodeNull() throws {
        let anyCodable = AnyCodable(value: NSNull())
        let data = try JSONEncoder().encode(anyCodable)
        let json = String(data: data, encoding: .utf8)!
        #expect(json == "null")
    }

    // MARK: - Error Tests

    @Test("Decode invalid value throws error")
    func decodeInvalidValue() throws {
        let json = "[1, 2, 3]"  // Arrays not supported
        let data = json.data(using: .utf8)!
        #expect(throws: DecodingError.self) {
            try JSONDecoder().decode(AnyCodable.self, from: data)
        }
    }

    @Test("Encode unsupported type throws error")
    func encodeUnsupportedType() throws {
        struct CustomType {}
        let anyCodable = AnyCodable(value: CustomType())
        #expect(throws: EncodingError.self) {
            try JSONEncoder().encode(anyCodable)
        }
    }

    // MARK: - Round-trip Tests

    @Test("Round-trip string value")
    func roundTripString() throws {
        let original = "hello"
        let anyCodable = AnyCodable(value: original)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? String == original)
    }

    @Test("Round-trip integer value")
    func roundTripInteger() throws {
        let original = 42
        let anyCodable = AnyCodable(value: original)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Int == original)
    }

    @Test("Round-trip double value")
    func roundTripDouble() throws {
        let original = 3.14159
        let anyCodable = AnyCodable(value: original)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Double == original)
    }

    @Test("Round-trip boolean value")
    func roundTripBoolean() throws {
        let original = true
        let anyCodable = AnyCodable(value: original)
        let data = try JSONEncoder().encode(anyCodable)
        let decoded = try JSONDecoder().decode(AnyCodable.self, from: data)
        #expect(decoded.value as? Bool == original)
    }
}

// MARK: - AnyCodable Extension for Testing

extension AnyCodable {
    init(value: Any) {
        self.value = value
    }
}
