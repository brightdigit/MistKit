//
//  DynamicKeyTests.swift
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

@Suite("DynamicKey Tests")
struct DynamicKeyTests {

    // MARK: - String Initialization Tests

    @Test("Initialize with string value")
    func initWithStringValue() {
        let key = DynamicKey(stringValue: "testKey")
        #expect(key != nil)
        #expect(key?.stringValue == "testKey")
        #expect(key?.intValue == nil)
    }

    @Test("Initialize with empty string")
    func initWithEmptyString() {
        let key = DynamicKey(stringValue: "")
        #expect(key != nil)
        #expect(key?.stringValue == "")
        #expect(key?.intValue == nil)
    }

    @Test("Initialize with string containing numbers")
    func initWithNumericString() {
        let key = DynamicKey(stringValue: "123")
        #expect(key != nil)
        #expect(key?.stringValue == "123")
        #expect(key?.intValue == nil)
    }

    @Test("Initialize with string containing special characters")
    func initWithSpecialCharacters() {
        let key = DynamicKey(stringValue: "field_name-123")
        #expect(key != nil)
        #expect(key?.stringValue == "field_name-123")
    }

    // MARK: - Integer Initialization Tests

    @Test("Initialize with integer value")
    func initWithIntValue() {
        let key = DynamicKey(intValue: 42)
        #expect(key != nil)
        #expect(key?.stringValue == "42")
        #expect(key?.intValue == 42)
    }

    @Test("Initialize with zero")
    func initWithZero() {
        let key = DynamicKey(intValue: 0)
        #expect(key != nil)
        #expect(key?.stringValue == "0")
        #expect(key?.intValue == 0)
    }

    @Test("Initialize with negative integer")
    func initWithNegativeInt() {
        let key = DynamicKey(intValue: -5)
        #expect(key != nil)
        #expect(key?.stringValue == "-5")
        #expect(key?.intValue == -5)
    }

    // MARK: - CodingKey Protocol Conformance Tests

    @Test("Use DynamicKey in decoding container")
    func useInDecodingContainer() throws {
        let json = """
        {
            "dynamicField": "value",
            "anotherField": 123
        }
        """
        let data = json.data(using: .utf8)!

        struct TestWrapper: Decodable {
            let fields: [String: String]

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: DynamicKey.self)
                var fields: [String: String] = [:]

                for key in container.allKeys {
                    if let value = try? container.decode(String.self, forKey: key) {
                        fields[key.stringValue] = value
                    } else if let intValue = try? container.decode(Int.self, forKey: key) {
                        fields[key.stringValue] = String(intValue)
                    }
                }

                self.fields = fields
            }
        }

        let decoded = try JSONDecoder().decode(TestWrapper.self, from: data)
        #expect(decoded.fields["dynamicField"] == "value")
        #expect(decoded.fields["anotherField"] == "123")
    }

    @Test("Use DynamicKey in encoding container")
    func useInEncodingContainer() throws {
        struct TestWrapper: Encodable {
            let fields: [String: String]

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: DynamicKey.self)

                for (key, value) in fields {
                    let dynamicKey = DynamicKey(stringValue: key)!
                    try container.encode(value, forKey: dynamicKey)
                }
            }
        }

        let wrapper = TestWrapper(fields: ["field1": "value1", "field2": "value2"])
        let data = try JSONEncoder().encode(wrapper)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

        #expect(json?["field1"] == "value1")
        #expect(json?["field2"] == "value2")
    }

    // MARK: - Equality Tests

    @Test("Keys with same string value are equal")
    func keysWithSameStringEqual() {
        let key1 = DynamicKey(stringValue: "test")
        let key2 = DynamicKey(stringValue: "test")
        #expect(key1?.stringValue == key2?.stringValue)
    }

    @Test("Keys with different string values are not equal")
    func keysWithDifferentStringNotEqual() {
        let key1 = DynamicKey(stringValue: "test1")
        let key2 = DynamicKey(stringValue: "test2")
        #expect(key1?.stringValue != key2?.stringValue)
    }
}
