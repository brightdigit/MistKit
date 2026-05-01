//
//  UpdateConfigTests.swift
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

@testable import MistDemoKit

@Suite("UpdateConfig Tests")
struct UpdateConfigTests {
    // MARK: - Basic Initialization Tests

    @Test("UpdateConfig initializes with defaults")
    func initializeWithDefaults() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1")

        #expect(config.recordName == "rec1")
        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Note")
        #expect(config.recordChangeTag == nil)
        #expect(config.force == false)
        #expect(config.fields.isEmpty)
        #expect(config.output == .json)
    }

    @Test("UpdateConfig initializes with custom zone")
    func initializeWithCustomZone() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, zone: "customZone", recordName: "rec1")

        #expect(config.zone == "customZone")
    }

    @Test("UpdateConfig initializes with custom record type")
    func initializeWithCustomRecordType() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordType: "Article", recordName: "rec1")

        #expect(config.recordType == "Article")
    }

    @Test("UpdateConfig initializes with record change tag")
    func initializeWithRecordChangeTag() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(
            base: baseConfig,
            recordName: "rec1",
            recordChangeTag: "tag-abc123"
        )

        #expect(config.recordChangeTag == "tag-abc123")
    }

    @Test("UpdateConfig initializes without record change tag")
    func initializeWithoutRecordChangeTag() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", recordChangeTag: nil)

        #expect(config.recordChangeTag == nil)
    }

    // MARK: - Force Flag Tests

    @Test("UpdateConfig defaults force to false")
    func forceDefaultsFalse() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1")

        #expect(config.force == false)
    }

    @Test("UpdateConfig accepts force=true")
    func forceCanBeTrue() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", force: true)

        #expect(config.force == true)
    }

    @Test("UpdateConfig preserves recordChangeTag when force is set (caller decides effect)")
    func forceWithChangeTagBothPreserved() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(
            base: baseConfig,
            recordName: "rec1",
            recordChangeTag: "tag-1",
            force: true
        )

        // The Config holds both values; UpdateCommand decides to ignore the tag when force=true.
        #expect(config.recordChangeTag == "tag-1")
        #expect(config.force == true)
    }

    // MARK: - Field Initialization Tests

    @Test("UpdateConfig initializes with empty fields")
    func initializeWithEmptyFields() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: [])

        #expect(config.fields.isEmpty)
    }

    @Test("UpdateConfig initializes with single field")
    func initializeWithSingleField() async throws {
        let baseConfig = try await MistDemoConfig()
        let field = Field(name: "title", type: .string, value: "Updated Title")
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: [field])

        #expect(config.fields.count == 1)
        #expect(config.fields[0].name == "title")
        #expect(config.fields[0].type == .string)
        #expect(config.fields[0].value == "Updated Title")
    }

    @Test("UpdateConfig initializes with multiple fields of various types")
    func initializeWithMultipleFields() async throws {
        let baseConfig = try await MistDemoConfig()
        let fields = [
            Field(name: "title", type: .string, value: "New Title"),
            Field(name: "count", type: .int64, value: "42"),
            Field(name: "ratio", type: .double, value: "3.14")
        ]
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: fields)

        #expect(config.fields.count == 3)
        #expect(config.fields[0].type == .string)
        #expect(config.fields[1].type == .int64)
        #expect(config.fields[2].type == .double)
    }

    // MARK: - Output Format Tests

    @Test("UpdateConfig accepts JSON output format")
    func outputJSON() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", output: .json)

        #expect(config.output == .json)
    }

    @Test("UpdateConfig accepts table output format")
    func outputTable() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", output: .table)

        #expect(config.output == .table)
    }

    @Test("UpdateConfig accepts CSV output format")
    func outputCSV() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", output: .csv)

        #expect(config.output == .csv)
    }

    @Test("UpdateConfig accepts YAML output format")
    func outputYAML() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec1", output: .yaml)

        #expect(config.output == .yaml)
    }

    // MARK: - Combined / Edge Cases

    @Test("UpdateConfig initializes with all custom values")
    func initializeWithAllCustomValues() async throws {
        let baseConfig = try await MistDemoConfig()
        let fields = [
            Field(name: "title", type: .string, value: "x"),
            Field(name: "n", type: .int64, value: "1")
        ]
        let config = UpdateConfig(
            base: baseConfig,
            zone: "Z",
            recordType: "T",
            recordName: "R",
            recordChangeTag: "tag",
            force: true,
            fields: fields,
            output: .yaml
        )

        #expect(config.zone == "Z")
        #expect(config.recordType == "T")
        #expect(config.recordName == "R")
        #expect(config.recordChangeTag == "tag")
        #expect(config.force == true)
        #expect(config.fields.count == 2)
        #expect(config.output == .yaml)
    }

    @Test("UpdateConfig handles special characters in record name")
    func specialCharactersInRecordName() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = UpdateConfig(base: baseConfig, recordName: "rec-name_with.special@chars")

        #expect(config.recordName == "rec-name_with.special@chars")
    }
}

@Suite("UpdateError Tests")
struct UpdateErrorTests {
    @Test("conflict with nil reason produces a generic conflict description")
    func conflictNilReason() {
        let error = UpdateError.conflict(reason: nil)
        let description = error.errorDescription ?? ""

        #expect(description.contains("conflict"))
    }

    @Test("conflict with reason includes the reason in the description")
    func conflictWithReason() {
        let error = UpdateError.conflict(reason: "ATOMIC_ERROR")
        let description = error.errorDescription ?? ""

        #expect(description.contains("ATOMIC_ERROR"))
    }

    @Test("conflict suggests --force as a remedy")
    func conflictRecoveryMentionsForce() {
        let error = UpdateError.conflict(reason: nil)
        let suggestion = error.recoverySuggestion ?? ""

        #expect(suggestion.contains("--force"))
    }

    @Test("recordNameRequired has a description")
    func recordNameRequiredDescription() {
        let error = UpdateError.recordNameRequired
        #expect(error.errorDescription != nil)
    }

    @Test("noFieldsProvided has a description")
    func noFieldsProvidedDescription() {
        let error = UpdateError.noFieldsProvided
        #expect(error.errorDescription != nil)
    }
}
