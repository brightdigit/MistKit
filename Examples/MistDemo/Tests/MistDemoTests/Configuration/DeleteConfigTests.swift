//
//  DeleteConfigTests.swift
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

@testable import MistDemoKit

@Suite("DeleteConfig Tests")
struct DeleteConfigTests {
    @Test("DeleteConfig initializes with defaults")
    func initializeWithDefaults() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(base: baseConfig, recordName: "rec-1")

        #expect(config.recordName == "rec-1")
        #expect(config.zone == "_defaultZone")
        #expect(config.recordType == "Note")
        #expect(config.recordChangeTag == nil)
        #expect(config.force == false)
        #expect(config.output == .json)
    }

    @Test("DeleteConfig initializes with custom zone and record type")
    func initializeWithCustomZoneAndType() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(
            base: baseConfig,
            zone: "myZone",
            recordType: "Article",
            recordName: "rec-1"
        )

        #expect(config.zone == "myZone")
        #expect(config.recordType == "Article")
    }

    @Test("DeleteConfig accepts a record change tag")
    func recordChangeTag() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(
            base: baseConfig,
            recordName: "rec-1",
            recordChangeTag: "tag-xyz"
        )

        #expect(config.recordChangeTag == "tag-xyz")
    }

    @Test("DeleteConfig defaults force to false")
    func forceDefaultsFalse() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(base: baseConfig, recordName: "rec-1")

        #expect(config.force == false)
    }

    @Test("DeleteConfig accepts force=true")
    func forceCanBeTrue() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(base: baseConfig, recordName: "rec-1", force: true)

        #expect(config.force == true)
    }

    @Test("DeleteConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
    func outputFormats(format: OutputFormat) async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(base: baseConfig, recordName: "rec-1", output: format)

        #expect(config.output == format)
    }

    @Test("DeleteConfig handles all custom values together")
    func allCustomValues() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(
            base: baseConfig,
            zone: "Z",
            recordType: "T",
            recordName: "R",
            recordChangeTag: "tag",
            force: true,
            output: .yaml
        )

        #expect(config.zone == "Z")
        #expect(config.recordType == "T")
        #expect(config.recordName == "R")
        #expect(config.recordChangeTag == "tag")
        #expect(config.force == true)
        #expect(config.output == .yaml)
    }

    @Test("DeleteConfig preserves special characters in record name")
    func specialCharactersInRecordName() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = DeleteConfig(base: baseConfig, recordName: "rec-name_with.special@chars")

        #expect(config.recordName == "rec-name_with.special@chars")
    }
}

@Suite("DeleteError Tests")
struct DeleteErrorTests {
    @Test("recordNameRequired has a description")
    func recordNameRequiredDescription() {
        let error = DeleteError.recordNameRequired
        #expect(error.errorDescription != nil)
    }

    @Test("conflict description includes the reason when present")
    func conflictWithReason() {
        let error = DeleteError.conflict(reason: "ATOMIC_ERROR")
        #expect(error.errorDescription?.contains("ATOMIC_ERROR") == true)
    }

    @Test("conflict description is generic when reason is nil")
    func conflictNoReason() {
        let error = DeleteError.conflict(reason: nil)
        #expect(error.errorDescription?.contains("conflict") == true)
    }

    @Test("conflict suggests --force as a remedy")
    func conflictRecoveryMentionsForce() {
        let error = DeleteError.conflict(reason: nil)
        #expect(error.recoverySuggestion?.contains("--force") == true)
    }
}

@Suite("DeleteResult Tests")
struct DeleteResultTests {
    @Test("DeleteResult encodes deleted=true by default")
    func defaultsToDeletedTrue() throws {
        let result = DeleteResult(recordName: "rec-1", recordType: "Note")
        let data = try JSONEncoder().encode(result)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"deleted\":true"))
        #expect(json.contains("\"recordName\":\"rec-1\""))
        #expect(json.contains("\"recordType\":\"Note\""))
    }
}
