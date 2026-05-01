//
//  ModifyConfigTests.swift
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

@Suite("ModifyConfig Tests")
struct ModifyConfigTests {
    @Test("ModifyConfig initializes with empty operations")
    func emptyOperations() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = ModifyConfig(base: baseConfig, operations: [])

        #expect(config.operations.isEmpty)
        #expect(config.atomic == false)
        #expect(config.output == .json)
    }

    @Test("ModifyConfig defaults atomic to false")
    func atomicDefaultsFalse() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = ModifyConfig(base: baseConfig, operations: [])

        #expect(config.atomic == false)
    }

    @Test("ModifyConfig accepts atomic=true")
    func atomicCanBeTrue() async throws {
        let baseConfig = try await MistDemoConfig()
        let config = ModifyConfig(base: baseConfig, operations: [], atomic: true)

        #expect(config.atomic == true)
    }

    @Test("ModifyConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
    func outputFormats(format: OutputFormat) async throws {
        let baseConfig = try await MistDemoConfig()
        let config = ModifyConfig(base: baseConfig, operations: [], output: format)

        #expect(config.output == format)
    }
}

@Suite("ModifyConfig JSON Parsing Tests")
struct ModifyConfigParsingTests {
    @Test("Parses a single create operation")
    func parseCreate() throws {
        let json = """
        [
          {"op":"create","recordType":"Note","fields":{"title":"Hello","priority":5}}
        ]
        """
        let data = Data(json.utf8)
        let ops = try ModifyConfig.parseOperations(from: data)

        #expect(ops.count == 1)
        #expect(ops[0].op == .create)
        #expect(ops[0].recordType == "Note")
        #expect(ops[0].recordName == nil)
        #expect(ops[0].fields != nil)
    }

    @Test("Parses an update operation with change tag")
    func parseUpdate() throws {
        let json = """
        [
          {
            "op":"update",
            "recordType":"Note",
            "recordName":"note-1",
            "recordChangeTag":"abc",
            "fields":{"title":"x"}
          }
        ]
        """
        let data = Data(json.utf8)
        let ops = try ModifyConfig.parseOperations(from: data)

        #expect(ops.count == 1)
        #expect(ops[0].op == .update)
        #expect(ops[0].recordName == "note-1")
        #expect(ops[0].recordChangeTag == "abc")
    }

    @Test("Parses a delete operation")
    func parseDelete() throws {
        let json = """
        [
          {"op":"delete","recordType":"Note","recordName":"note-1"}
        ]
        """
        let data = Data(json.utf8)
        let ops = try ModifyConfig.parseOperations(from: data)

        #expect(ops.count == 1)
        #expect(ops[0].op == .delete)
        #expect(ops[0].recordName == "note-1")
    }

    @Test("Parses a mixed batch")
    func parseMixedBatch() throws {
        let json = """
        [
          {"op":"create","recordType":"Note","fields":{"title":"A"}},
          {"op":"update","recordType":"Note","recordName":"n1","fields":{"title":"B"}},
          {"op":"delete","recordType":"Note","recordName":"n2"}
        ]
        """
        let data = Data(json.utf8)
        let ops = try ModifyConfig.parseOperations(from: data)

        #expect(ops.count == 3)
        #expect(ops[0].op == .create)
        #expect(ops[1].op == .update)
        #expect(ops[2].op == .delete)
    }

    @Test("Rejects an unknown op")
    func rejectsUnknownOp() throws {
        let json = """
        [
          {"op":"frobnicate","recordType":"Note"}
        ]
        """
        let data = Data(json.utf8)

        #expect(throws: ModifyError.self) {
            _ = try ModifyConfig.parseOperations(from: data)
        }
    }

    @Test("Rejects malformed JSON")
    func rejectsMalformedJSON() throws {
        let json = "not even json"
        let data = Data(json.utf8)

        #expect(throws: ModifyError.self) {
            _ = try ModifyConfig.parseOperations(from: data)
        }
    }
}

@Suite("ModifyOperationInput Validation Tests")
struct ModifyOperationInputTests {
    @Test("update requires a recordName")
    func updateRequiresRecordName() throws {
        let input = ModifyOperationInput(op: .update, recordType: "Note", recordName: nil)

        #expect(throws: ModifyError.self) {
            _ = try input.toRecordOperation(index: 0)
        }
    }

    @Test("delete requires a recordName")
    func deleteRequiresRecordName() throws {
        let input = ModifyOperationInput(op: .delete, recordType: "Note", recordName: nil)

        #expect(throws: ModifyError.self) {
            _ = try input.toRecordOperation(index: 0)
        }
    }

    @Test("create succeeds without a recordName")
    func createWithoutRecordName() throws {
        let input = ModifyOperationInput(op: .create, recordType: "Note", recordName: nil)
        let op = try input.toRecordOperation(index: 0)

        #expect(op.recordName == nil)
        #expect(op.recordType == "Note")
    }
}

@Suite("ModifyError Tests")
struct ModifyErrorTests {
    @Test("operationsRequired has a description")
    func operationsRequiredDescription() {
        #expect(ModifyError.operationsRequired.errorDescription != nil)
    }

    @Test("missingRecordName description includes index and op")
    func missingRecordNameDescription() {
        let error = ModifyError.missingRecordName(opIndex: 2, op: "update")
        let description = error.errorDescription ?? ""

        #expect(description.contains("2"))
        #expect(description.contains("update"))
    }

    @Test("invalidOperationType description includes the op")
    func invalidOperationTypeDescription() {
        let error = ModifyError.invalidOperationType("frobnicate")
        #expect(error.errorDescription?.contains("frobnicate") == true)
    }
}
