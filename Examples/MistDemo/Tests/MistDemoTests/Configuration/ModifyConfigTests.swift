// swiftlint:disable file_length
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
import MistKit
import Testing

@testable import MistDemoKit

// swiftlint:disable file_types_order one_declaration_per_file
@Suite("ModifyConfig Tests")
internal struct ModifyConfigTests {
  @Test("ModifyConfig initializes with empty operations")
  internal func emptyOperations() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [])

    #expect(config.operations.isEmpty)
    #expect(config.atomic == false)
    #expect(config.output == .json)
  }

  @Test("ModifyConfig defaults atomic to false")
  internal func atomicDefaultsFalse() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [])

    #expect(config.atomic == false)
  }

  @Test("ModifyConfig accepts atomic=true")
  internal func atomicCanBeTrue() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [], atomic: true)

    #expect(config.atomic == true)
  }

  @Test(
    "ModifyConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [], output: format)

    #expect(config.output == format)
  }
}

@Suite("ModifyConfig JSON Parsing Tests")
internal struct ModifyConfigParsingTests {
  @Test("Parses a single create operation")
  internal func parseCreate() throws {
    let json = """
      [
        {"op":"create","recordType":"Note","fields":{"title":"Hello","priority":5}}
      ]
      """
    let data = Data(json.utf8)
    let ops = try ModifyConfig.parseOperations(from: data)

    #expect(ops.count == 1)
    #expect(ops[0].operation == .create)
    #expect(ops[0].recordType == "Note")
    #expect(ops[0].recordName == nil)
    #expect(ops[0].fields != nil)
  }

  @Test("Parses an update operation with change tag")
  internal func parseUpdate() throws {
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
    #expect(ops[0].operation == .update)
    #expect(ops[0].recordName == "note-1")
    #expect(ops[0].recordChangeTag == "abc")
  }

  @Test("Parses a delete operation")
  internal func parseDelete() throws {
    let json = """
      [
        {"op":"delete","recordType":"Note","recordName":"note-1"}
      ]
      """
    let data = Data(json.utf8)
    let ops = try ModifyConfig.parseOperations(from: data)

    #expect(ops.count == 1)
    #expect(ops[0].operation == .delete)
    #expect(ops[0].recordName == "note-1")
  }

  @Test("Parses a mixed batch")
  internal func parseMixedBatch() throws {
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
    #expect(ops[0].operation == .create)
    #expect(ops[1].operation == .update)
    #expect(ops[2].operation == .delete)
  }

  @Test("Rejects an unknown op")
  internal func rejectsUnknownOp() throws {
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
  internal func rejectsMalformedJSON() throws {
    let json = "not even json"
    let data = Data(json.utf8)

    #expect(throws: ModifyError.self) {
      _ = try ModifyConfig.parseOperations(from: data)
    }
  }
}

@Suite("ModifyOperationInput Validation Tests")
internal struct ModifyOperationInputTests {
  @Test("update requires a recordName")
  internal func updateRequiresRecordName() throws {
    let input = ModifyOperationInput(operation: .update, recordType: "Note", recordName: nil)

    #expect(throws: ModifyError.self) {
      _ = try input.toRecordOperation(index: 0)
    }
  }

  @Test("delete requires a recordName")
  internal func deleteRequiresRecordName() throws {
    let input = ModifyOperationInput(operation: .delete, recordType: "Note", recordName: nil)

    #expect(throws: ModifyError.self) {
      _ = try input.toRecordOperation(index: 0)
    }
  }

  @Test("create succeeds without a recordName")
  internal func createWithoutRecordName() throws {
    let input = ModifyOperationInput(operation: .create, recordType: "Note", recordName: nil)
    let operation = try input.toRecordOperation(index: 0)

    #expect(operation.recordName == nil)
    #expect(operation.recordType == "Note")
  }
}

@Suite("ModifyError Tests")
internal struct ModifyErrorTests {
  @Test("operationsRequired has a description")
  internal func operationsRequiredDescription() {
    #expect(ModifyError.operationsRequired.errorDescription != nil)
  }

  @Test("missingRecordName description includes index and op")
  internal func missingRecordNameDescription() {
    let error = ModifyError.missingRecordName(opIndex: 2, operation: "update")
    let description = error.errorDescription ?? ""

    #expect(description.contains("2"))
    #expect(description.contains("update"))
  }

  @Test("invalidOperationType description includes the op")
  internal func invalidOperationTypeDescription() {
    let error = ModifyError.invalidOperationType("frobnicate")
    #expect(error.errorDescription?.contains("frobnicate") == true)
  }
}

// swiftlint:enable file_types_order one_declaration_per_file
