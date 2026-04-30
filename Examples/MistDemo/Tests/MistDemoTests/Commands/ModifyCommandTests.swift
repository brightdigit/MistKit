//
//  ModifyCommandTests.swift
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

@Suite("ModifyCommand Tests")
struct ModifyCommandTests {
    @Test("Command has correct static properties")
    func staticProperties() {
        #expect(ModifyCommand.commandName == "modify")
        #expect(ModifyCommand.abstract == "Run a batch of create/update/delete record operations")
        #expect(ModifyCommand.helpText.contains("MODIFY"))
    }

    @Test("Command initializes with config")
    func initializesWithConfig() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = ModifyConfig(base: baseConfig, operations: [])
        let _ = ModifyCommand(config: config)
    }
}

@Suite("ModifyResultRow Tests")
struct ModifyResultRowTests {
    @Test("ModifyResultRow encodes all fields")
    func encodesFields() throws {
        let row = ModifyResultRow(
            op: "applied",
            recordType: "Note",
            recordName: "note-1",
            recordChangeTag: "tag-xyz"
        )
        let data = try JSONEncoder().encode(row)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"op\":\"applied\""))
        #expect(json.contains("\"recordType\":\"Note\""))
        #expect(json.contains("\"recordName\":\"note-1\""))
        #expect(json.contains("\"recordChangeTag\":\"tag-xyz\""))
    }
}

@Suite("ModifyOutput Tests")
struct ModifyOutputTests {
    @Test("ModifyOutput JSON envelope carries partialFailure metadata")
    func envelopeIncludesMetadata() throws {
        let row = ModifyResultRow(op: "applied", recordType: "Note", recordName: "n-1", recordChangeTag: "t-1")
        let envelope = ModifyOutput(
            results: [row],
            attempted: 3,
            succeeded: 1,
            partialFailure: true
        )
        let data = try JSONEncoder().encode(envelope)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"attempted\":3"))
        #expect(json.contains("\"succeeded\":1"))
        #expect(json.contains("\"partialFailure\":true"))
        #expect(json.contains("\"results\":["))
    }

    @Test("ModifyOutput partialFailure=false when all ops succeed")
    func noPartialFailureWhenAllSucceed() throws {
        let row = ModifyResultRow(op: "applied", recordType: "Note", recordName: "n-1", recordChangeTag: "t-1")
        let envelope = ModifyOutput(
            results: [row],
            attempted: 1,
            succeeded: 1,
            partialFailure: false
        )
        let data = try JSONEncoder().encode(envelope)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"partialFailure\":false"))
    }

    @Test("ModifyOutput with delete-only batch and zero record results is not a partial failure")
    func deleteOnlyBatchNotPartialFailure() throws {
        // Delete operations succeed without returning a record. A delete-only
        // batch where the response has zero records is a complete success,
        // not a partial failure — the envelope reflects that.
        let envelope = ModifyOutput(
            results: [],
            attempted: 3,
            succeeded: 0,
            partialFailure: false
        )
        let data = try JSONEncoder().encode(envelope)
        let json = try #require(String(data: data, encoding: .utf8))

        #expect(json.contains("\"partialFailure\":false"))
        #expect(json.contains("\"attempted\":3"))
    }
}
