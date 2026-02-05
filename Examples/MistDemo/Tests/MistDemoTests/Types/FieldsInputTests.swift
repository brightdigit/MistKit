//
//  FieldsInputTests.swift
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

@Suite("FieldsInput Tests")
struct FieldsInputTests {

    // MARK: - String Field Decoding Tests

    @Test("Decode string field")
    func decodeStringField() throws {
        let json = """
        {
            "title": "Hello World"
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "title")
        #expect(fields[0].type == .string)
        #expect(fields[0].value == "Hello World")
    }

    @Test("Decode empty string field")
    func decodeEmptyStringField() throws {
        let json = """
        {
            "description": ""
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "description")
        #expect(fields[0].type == .string)
        #expect(fields[0].value == "")
    }

    // MARK: - Integer Field Decoding Tests

    @Test("Decode integer field")
    func decodeIntField() throws {
        let json = """
        {
            "count": 42
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "count")
        #expect(fields[0].type == .int64)
        #expect(fields[0].value == "42")
    }

    @Test("Decode negative integer field")
    func decodeNegativeIntField() throws {
        let json = """
        {
            "temperature": -10
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "temperature")
        #expect(fields[0].type == .int64)
        #expect(fields[0].value == "-10")
    }

    @Test("Decode zero integer field")
    func decodeZeroIntField() throws {
        let json = """
        {
            "balance": 0
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "balance")
        #expect(fields[0].type == .int64)
        #expect(fields[0].value == "0")
    }

    // MARK: - Double Field Decoding Tests

    @Test("Decode double field")
    func decodeDoubleField() throws {
        let json = """
        {
            "price": 19.99
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "price")
        #expect(fields[0].type == .double)
        #expect(fields[0].value == "19.99")
    }

    @Test("Decode negative double field")
    func decodeNegativeDoubleField() throws {
        let json = """
        {
            "latitude": -33.8688
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "latitude")
        #expect(fields[0].type == .double)
        #expect(fields[0].value == "-33.8688")
    }

    // MARK: - Boolean Field Decoding Tests

    @Test("Decode true boolean field")
    func decodeTrueBoolField() throws {
        let json = """
        {
            "isActive": true
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "isActive")
        #expect(fields[0].type == .string)
        #expect(fields[0].value == "true")
    }

    @Test("Decode false boolean field")
    func decodeFalseBoolField() throws {
        let json = """
        {
            "isEnabled": false
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "isEnabled")
        #expect(fields[0].type == .string)
        #expect(fields[0].value == "false")
    }

    // MARK: - Multiple Fields Tests

    @Test("Decode multiple mixed type fields")
    func decodeMultipleFields() throws {
        let json = """
        {
            "title": "Test Item",
            "count": 5,
            "price": 9.99,
            "active": true
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 4)

        let fieldsByName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0) })

        #expect(fieldsByName["title"]?.type == .string)
        #expect(fieldsByName["title"]?.value == "Test Item")

        #expect(fieldsByName["count"]?.type == .int64)
        #expect(fieldsByName["count"]?.value == "5")

        #expect(fieldsByName["price"]?.type == .double)
        #expect(fieldsByName["price"]?.value == "9.99")

        #expect(fieldsByName["active"]?.type == .string)
        #expect(fieldsByName["active"]?.value == "true")
    }

    @Test("Decode empty object")
    func decodeEmptyObject() throws {
        let json = "{}"
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.isEmpty)
    }

    // MARK: - Encoding Tests

    @Test("Encode and decode string field")
    func encodeDecodeStringField() throws {
        let json = """
        {
            "name": "Test"
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

        let encoded = try JSONEncoder().encode(fieldsInput)
        let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
        let fields = try decoded.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "name")
        #expect(fields[0].value == "Test")
    }

    @Test("Encode and decode integer field")
    func encodeDecodeIntField() throws {
        let json = """
        {
            "count": 100
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

        let encoded = try JSONEncoder().encode(fieldsInput)
        let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
        let fields = try decoded.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "count")
        #expect(fields[0].type == .int64)
        #expect(fields[0].value == "100")
    }

    @Test("Encode and decode multiple fields")
    func encodeDecodeMultipleFields() throws {
        let json = """
        {
            "title": "Item",
            "quantity": 3,
            "price": 15.50
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

        let encoded = try JSONEncoder().encode(fieldsInput)
        let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
        let fields = try decoded.toFields()

        #expect(fields.count == 3)
    }

    // MARK: - Field Name Tests

    @Test("Decode field with underscore in name")
    func decodeFieldWithUnderscore() throws {
        let json = """
        {
            "field_name": "value"
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "field_name")
    }

    @Test("Decode field with camelCase name")
    func decodeFieldWithCamelCase() throws {
        let json = """
        {
            "firstName": "John"
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].name == "firstName")
    }

    // MARK: - Special Value Tests

    @Test("Decode field with whitespace in string value")
    func decodeFieldWithWhitespace() throws {
        let json = """
        {
            "description": "  spaced text  "
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].value == "  spaced text  ")
    }

    @Test("Decode field with unicode characters")
    func decodeFieldWithUnicode() throws {
        let json = """
        {
            "emoji": "🎉"
        }
        """
        let data = Data(json.utf8)
        let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
        let fields = try fieldsInput.toFields()

        #expect(fields.count == 1)
        #expect(fields[0].value == "🎉")
    }
}
