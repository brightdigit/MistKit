//
//  CurrentUserConfigTests.swift
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

@Suite("CurrentUserConfig Tests")
struct CurrentUserConfigTests {
    // MARK: - Basic Initialization Tests

    @Test("CurrentUserConfig initializes with default values")
    func initializeWithDefaults() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(base: baseConfig)

        #expect(config.fields == nil)
        #expect(config.output == .json)
    }

    @Test("CurrentUserConfig initializes with nil fields")
    func initializeWithNilFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: nil
        )

        #expect(config.fields == nil)
    }

    @Test("CurrentUserConfig initializes with empty fields array")
    func initializeWithEmptyFieldsArray() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: []
        )

        #expect(config.fields != nil)
        #expect(config.fields?.isEmpty == true)
    }

    // MARK: - Fields Tests

    @Test("CurrentUserConfig initializes with single field")
    func initializeWithSingleField() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName"]
        )

        #expect(config.fields?.count == 1)
        #expect(config.fields?[0] == "userRecordName")
    }

    @Test("CurrentUserConfig initializes with multiple fields")
    func initializeWithMultipleFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName", "firstName", "lastName"]
        )

        #expect(config.fields?.count == 3)
        #expect(config.fields?[0] == "userRecordName")
        #expect(config.fields?[1] == "firstName")
        #expect(config.fields?[2] == "lastName")
    }

    @Test("CurrentUserConfig handles standard user fields")
    func handleStandardUserFields() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: [
                "userRecordName",
                "firstName",
                "lastName",
                "emailAddress",
                "iCloudId"
            ]
        )

        #expect(config.fields?.count == 5)
        #expect(config.fields?.contains("userRecordName") == true)
        #expect(config.fields?.contains("emailAddress") == true)
    }

    // MARK: - Output Format Tests

    @Test("CurrentUserConfig initializes with JSON output format")
    func initializeWithJSONOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            output: .json
        )

        #expect(config.output == .json)
    }

    @Test("CurrentUserConfig initializes with CSV output format")
    func initializeWithCSVOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            output: .csv
        )

        #expect(config.output == .csv)
    }

    @Test("CurrentUserConfig initializes with table output format")
    func initializeWithTableOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            output: .table
        )

        #expect(config.output == .table)
    }

    @Test("CurrentUserConfig initializes with YAML output format")
    func initializeWithYAMLOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            output: .yaml
        )

        #expect(config.output == .yaml)
    }

    // MARK: - Complex Initialization Tests

    @Test("CurrentUserConfig initializes with all custom values")
    func initializeWithAllCustomValues() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName", "firstName", "lastName"],
            output: .yaml
        )

        #expect(config.fields?.count == 3)
        #expect(config.output == .yaml)
    }

    @Test("CurrentUserConfig handles fields and JSON output")
    func handleFieldsWithJSONOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["userRecordName", "emailAddress"],
            output: .json
        )

        #expect(config.fields?.count == 2)
        #expect(config.output == .json)
    }

    @Test("CurrentUserConfig handles fields and CSV output")
    func handleFieldsWithCSVOutput() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["firstName", "lastName"],
            output: .csv
        )

        #expect(config.fields?.count == 2)
        #expect(config.output == .csv)
    }

    // MARK: - Edge Cases

    @Test("CurrentUserConfig handles single character field name")
    func handleSingleCharacterFieldName() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["x"]
        )

        #expect(config.fields?.count == 1)
        #expect(config.fields?[0] == "x")
    }

    @Test("CurrentUserConfig handles fields with special characters")
    func handleFieldsWithSpecialCharacters() throws {
        let baseConfig = try MistDemoConfig()
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: ["field_name", "field-with-dash", "field.with.dot"]
        )

        #expect(config.fields?.count == 3)
        #expect(config.fields?[0] == "field_name")
        #expect(config.fields?[1] == "field-with-dash")
        #expect(config.fields?[2] == "field.with.dot")
    }

    @Test("CurrentUserConfig handles very long field name")
    func handleVeryLongFieldName() throws {
        let baseConfig = try MistDemoConfig()
        let longFieldName = String(repeating: "a", count: 100)
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: [longFieldName]
        )

        #expect(config.fields?.count == 1)
        #expect(config.fields?[0].count == 100)
    }

    @Test("CurrentUserConfig handles many fields")
    func handleManyFields() throws {
        let baseConfig = try MistDemoConfig()
        let fields = (0..<20).map { "field\($0)" }
        let config = CurrentUserConfig(
            base: baseConfig,
            fields: fields
        )

        #expect(config.fields?.count == 20)
        #expect(config.fields?[0] == "field0")
        #expect(config.fields?[19] == "field19")
    }
}
