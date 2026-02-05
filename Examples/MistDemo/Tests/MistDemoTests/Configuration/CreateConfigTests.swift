//
//  CreateConfigTests.swift
//  MistDemoTests
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

@Suite("CreateConfig Tests")
struct CreateConfigTests {
    // MARK: - Basic Initialization Tests

    @Test("CreateConfig initializes with default values")
    func initializeWithDefaults() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(base: baseConfig)

        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Note")
        #expect(config.recordName == nil)
        #expect(config.fields.isEmpty)
        #expect(config.output == .json)
    }

    @Test("CreateConfig initializes with custom zone")
    func initializeWithCustomZone() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            zone: "customZone"
        )

        #expect(config.zone == "customZone")
        #expect(config.recordType == "Note")
    }

    @Test("CreateConfig initializes with custom record type")
    func initializeWithCustomRecordType() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            recordType: "Article"
        )

        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Article")
    }

    @Test("CreateConfig initializes with custom record name")
    func initializeWithCustomRecordName() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            recordName: "myRecord123"
        )

        #expect(config.recordName == "myRecord123")
    }

    @Test("CreateConfig initializes with nil record name")
    func initializeWithNilRecordName() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            recordName: nil
        )

        #expect(config.recordName == nil)
    }

    // MARK: - Field Initialization Tests

    @Test("CreateConfig initializes with empty fields")
    func initializeWithEmptyFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            fields: []
        )

        #expect(config.fields.isEmpty)
    }

    @Test("CreateConfig initializes with single field")
    func initializeWithSingleField() throws {
        let baseConfig = try MistDemoConfig()
        let field = Field(name: "title", type: .string, value: "Hello World")
        let config = CreateConfig(
            base: baseConfig,
            fields: [field]
        )

        #expect(config.fields.count == 1)
        #expect(config.fields[0].name == "title")
        #expect(config.fields[0].type == .string)
        #expect(config.fields[0].value == "Hello World")
    }

    @Test("CreateConfig initializes with multiple fields")
    func initializeWithMultipleFields() throws {
        let baseConfig = try MistDemoConfig()
        let fields = [
            Field(name: "title", type: .string, value: "Test Title"),
            Field(name: "count", type: .int64, value: "42"),
            Field(name: "price", type: .double, value: "99.99")
        ]
        let config = CreateConfig(
            base: baseConfig,
            fields: fields
        )

        #expect(config.fields.count == 3)
        #expect(config.fields[0].name == "title")
        #expect(config.fields[1].name == "count")
        #expect(config.fields[2].name == "price")
    }

    @Test("CreateConfig initializes with different field types")
    func initializeWithDifferentFieldTypes() throws {
        let baseConfig = try MistDemoConfig()
        let fields = [
            Field(name: "stringField", type: .string, value: "text"),
            Field(name: "intField", type: .int64, value: "100"),
            Field(name: "doubleField", type: .double, value: "3.14"),
            Field(name: "timestampField", type: .timestamp, value: "1234567890000"),
            Field(name: "bytesField", type: .bytes, value: "ZGF0YQ==")
        ]
        let config = CreateConfig(
            base: baseConfig,
            fields: fields
        )

        #expect(config.fields.count == 5)
        #expect(config.fields[0].type == .string)
        #expect(config.fields[1].type == .int64)
        #expect(config.fields[2].type == .double)
        #expect(config.fields[3].type == .timestamp)
        #expect(config.fields[4].type == .bytes)
    }

    // MARK: - Output Format Tests

    @Test("CreateConfig initializes with JSON output format")
    func initializeWithJSONOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            output: .json
        )

        #expect(config.output == .json)
    }

    @Test("CreateConfig initializes with CSV output format")
    func initializeWithCSVOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            output: .csv
        )

        #expect(config.output == .csv)
    }

    @Test("CreateConfig initializes with table output format")
    func initializeWithTableOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            output: .table
        )

        #expect(config.output == .table)
    }

    @Test("CreateConfig initializes with YAML output format")
    func initializeWithYAMLOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            output: .yaml
        )

        #expect(config.output == .yaml)
    }

    // MARK: - Complex Initialization Tests

    @Test("CreateConfig initializes with all custom values")
    func initializeWithAllCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let fields = [
            Field(name: "name", type: .string, value: "John Doe"),
            Field(name: "age", type: .int64, value: "30")
        ]
        let config = CreateConfig(
            base: baseConfig,
            zone: "customZone",
            recordType: "Person",
            recordName: "person001",
            fields: fields,
            output: .yaml
        )

        #expect(config.zone == "customZone")
        #expect(config.recordType == "Person")
        #expect(config.recordName == "person001")
        #expect(config.fields.count == 2)
        #expect(config.output == .yaml)
    }

    // MARK: - Edge Cases

    @Test("CreateConfig handles special characters in zone name")
    func handleSpecialCharactersInZone() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            zone: "zone_with-special.chars"
        )

        #expect(config.zone == "zone_with-special.chars")
    }

    @Test("CreateConfig handles special characters in record type")
    func handleSpecialCharactersInRecordType() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            recordType: "Record_Type-123"
        )

        #expect(config.recordType == "Record_Type-123")
    }

    @Test("CreateConfig handles special characters in record name")
    func handleSpecialCharactersInRecordName() throws {
        let baseConfig = try MistDemoConfig()
        let config = CreateConfig(
            base: baseConfig,
            recordName: "record-name_with.special@chars"
        )

        #expect(config.recordName == "record-name_with.special@chars")
    }

    @Test("CreateConfig handles field with empty string value")
    func handleFieldWithEmptyValue() throws {
        let baseConfig = try MistDemoConfig()
        let field = Field(name: "emptyField", type: .string, value: "")
        let config = CreateConfig(
            base: baseConfig,
            fields: [field]
        )

        #expect(config.fields.count == 1)
        #expect(config.fields[0].value == "")
    }

    @Test("CreateConfig handles field with whitespace value")
    func handleFieldWithWhitespaceValue() throws {
        let baseConfig = try MistDemoConfig()
        let field = Field(name: "whitespaceField", type: .string, value: "   ")
        let config = CreateConfig(
            base: baseConfig,
            fields: [field]
        )

        #expect(config.fields.count == 1)
        #expect(config.fields[0].value == "   ")
    }

    @Test("CreateConfig handles very long field value")
    func handleVeryLongFieldValue() throws {
        let baseConfig = try MistDemoConfig()
        let longValue = String(repeating: "a", count: 1000)
        let field = Field(name: "longField", type: .string, value: longValue)
        let config = CreateConfig(
            base: baseConfig,
            fields: [field]
        )

        #expect(config.fields.count == 1)
        #expect(config.fields[0].value.count == 1000)
    }

    @Test("CreateConfig handles many fields")
    func handleManyFields() throws {
        let baseConfig = try MistDemoConfig()
        let fields = (0..<20).map { index in
            Field(name: "field\(index)", type: .string, value: "value\(index)")
        }
        let config = CreateConfig(
            base: baseConfig,
            fields: fields
        )

        #expect(config.fields.count == 20)
        #expect(config.fields[0].name == "field0")
        #expect(config.fields[19].name == "field19")
    }
}
