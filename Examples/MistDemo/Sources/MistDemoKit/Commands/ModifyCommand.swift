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

/// Command to perform batch create/update/delete operations.
public struct ModifyCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = ModifyConfig
  /// The command name.
  public static let commandName = "modify"
  /// The command abstract.
  public static let abstract =
    "Run a batch of create/update/delete operations"
  /// The command help text.
  public static let helpText = """
    MODIFY - Batch create/update/delete operations

    USAGE:
      mistdemo modify --operations-file <path> [options]
      cat ops.json | mistdemo modify --stdin [options]

    INPUT (choose one):
      --operations-file <path>   Path to JSON array of ops
      --stdin                    Read JSON from stdin

    OPTIONS:
      --atomic                   Reject batch if any fails
      --output-format <format>   Output format

    NOTES:
      Without --atomic, the server may apply some ops and
      reject others.
    """

  private let config: ModifyConfig

  /// Creates a new instance.
  public init(config: ModifyConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      let client = try MistKitClientFactory.create(
        for: config.base
      )

      let operations = try config.operations.enumerated()
        .map { index, input in
          try input.toRecordOperation(index: index)
        }

      let results = try await client.modifyRecords(
        operations,
        atomic: config.atomic,
        database: config.base.database
      )

      let rows = results.map { record in
        ModifyResultRow(
          operation: "applied",
          recordType: record.recordType,
          recordName: record.recordName,
          recordChangeTag: record.recordChangeTag
        )
      }

      let recordReturningOpsCount =
        config.operations
        .filter { $0.operation != .delete }.count
      let partialFailure =
        !config.atomic
        && results.count < recordReturningOpsCount

      if partialFailure {
        let missing = recordReturningOpsCount - results.count
        let line =
          "Warning: \(missing) of \(recordReturningOpsCount)"
          + " create/update op(s) did not return a record.\n"
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
      throw ModifyError.operationFailed(
        error.localizedDescription
      )
    }
  }
}
