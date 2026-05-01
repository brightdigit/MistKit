//
//  ModifyCommand.swift
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
import MistKit

/// One row in the modify command's output: original op, plus the resulting record (if any).
public struct ModifyResultRow: Encodable, Sendable {
    public let op: String
    public let recordType: String
    public let recordName: String?
    public let recordChangeTag: String?

    public init(op: String, recordType: String, recordName: String?, recordChangeTag: String?) {
        self.op = op
        self.recordType = recordType
        self.recordName = recordName
        self.recordChangeTag = recordChangeTag
    }
}

/// JSON envelope for modify output. Carries enough metadata for scripts to
/// detect partial failures without parsing stderr.
public struct ModifyOutput: Encodable, Sendable {
    public let results: [ModifyResultRow]
    public let attempted: Int
    public let succeeded: Int
    public let partialFailure: Bool

    public init(results: [ModifyResultRow], attempted: Int, succeeded: Int, partialFailure: Bool) {
        self.results = results
        self.attempted = attempted
        self.succeeded = succeeded
        self.partialFailure = partialFailure
    }
}

/// Command to perform a batch of create/update/delete operations against CloudKit.
public struct ModifyCommand: MistDemoCommand, OutputFormatting {
    public typealias Config = ModifyConfig
    public static let commandName = "modify"
    public static let abstract = "Run a batch of create/update/delete record operations"
    public static let helpText = """
        MODIFY - Run a batch of create/update/delete record operations

        USAGE:
            mistdemo modify --operations-file <path> [options]
            cat ops.json | mistdemo modify --stdin [options]

        REQUIRED:
            --api-token <token>            CloudKit API token
            --web-auth-token <token>       Web authentication token

        INPUT (choose one):
            --operations-file <path>       Path to a JSON array of operations
            --stdin                        Read JSON array of operations from stdin

        OPTIONS:
            --atomic                       Reject the entire batch if any op fails
            --output-format <format>       Output format: json, table, csv, yaml

        OPERATIONS JSON FORMAT:

            [
              {
                "op": "create",
                "recordType": "Note",
                "fields": { "title": "Hello", "priority": 5 }
              },
              {
                "op": "update",
                "recordType": "Note",
                "recordName": "note-123",
                "recordChangeTag": "abc",
                "fields": { "title": "Updated" }
              },
              {
                "op": "delete",
                "recordType": "Note",
                "recordName": "note-456"
              }
            ]

        EXAMPLES:

          1. Run a batch atomically:
             mistdemo modify --operations-file ops.json --atomic

          2. Stream from stdin:
             cat ops.json | mistdemo modify --stdin

        NOTES:
          • Without --atomic, the server may apply some operations and reject
            others. The output reflects only the operations that succeeded.
          • Update and delete operations require a recordName. Create may omit
            it (the server will generate one).
        """

    private let config: ModifyConfig

    public init(config: ModifyConfig) {
        self.config = config
    }

    public func execute() async throws {
        do {
            let client = try MistKitClientFactory.create(.private, from: config.base)

            // Build [RecordOperation] from the JSON ops, validating each
            let operations = try config.operations.enumerated().map { index, input in
                try input.toRecordOperation(index: index)
            }

            let results = try await client.modifyRecords(operations, atomic: config.atomic)

            let rows = results.map { record in
                ModifyResultRow(
                    op: "applied",
                    recordType: record.recordType,
                    recordName: record.recordName,
                    recordChangeTag: record.recordChangeTag
                )
            }

            // Only create/update operations are expected to return a record.
            // Delete operations succeed by their absence in the response, so
            // counting them as "missing" would falsely trip the partial-failure signal.
            let recordReturningOpsCount = config.operations.filter { $0.op != .delete }.count
            let partialFailure = !config.atomic && results.count < recordReturningOpsCount

            if partialFailure {
                let missing = recordReturningOpsCount - results.count
                let line = "Warning: \(missing) of \(recordReturningOpsCount) create/update operation(s) did not return a record (possibly rejected by the server).\n"
                FileHandle.standardError.write(Data(line.utf8))
            }

            let envelope = ModifyOutput(
                results: rows,
                attempted: config.operations.count,
                succeeded: results.count,
                partialFailure: partialFailure
            )
            try await outputResult(envelope, format: config.output)

        } catch let error as ModifyError {
            throw error
        } catch {
            throw ModifyError.operationFailed(error.localizedDescription)
        }
    }
}
