//
//  LookupAllRecordsCommand.swift
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

internal import Foundation
internal import MistKit

/// Command to look up records by name using the auto-chunking
/// `lookupAllRecords` convenience (issue #307).
public struct LookupAllRecordsCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = LookupConfig
  /// The command name.
  public static let commandName = "lookup-all"
  /// The command abstract.
  public static let abstract =
    "Look up records by name, auto-chunking large inputs (lookupAllRecords)"
  /// The command help text.
  public static let helpText = """
    LOOKUP-ALL - Fetch records by name, auto-chunking past CloudKit's 200/request cap

    USAGE:
      mistdemo lookup-all --record-names <names> [options]

    REQUIRED:
      --api-token <token>          CloudKit API token
      --web-auth-token <token>     Web authentication token
      --record-names <names>       Comma-separated record names

    OPTIONS:
      --fields <field1,field2,...> Restrict returned fields
      --batch-size <n>             Items per request (default 200, clamped 1...200).
                                   Set small (e.g. 1) to force multiple requests.
      --output-format <format>     Output format (json, table, csv, yaml)

    EXAMPLES:
      mistdemo lookup-all --record-names note-1,note-2,note-3 --batch-size 1
    """

  private let config: LookupConfig

  /// Creates a new instance.
  public init(config: LookupConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    let client = try MistKitClientFactory.create(for: config.base)

    let effectiveBatchSize = min(
      max(config.batchSize, 1),
      CloudKitService.maxRecordsPerRequest
    )
    let batches =
      (config.recordNames.count + effectiveBatchSize - 1) / effectiveBatchSize
    let note =
      "lookup-all: \(config.recordNames.count) name(s), batchSize \(config.batchSize) "
      + "→ \(batches) request(s)\n"
    FileHandle.standardError.write(Data(note.utf8))

    let results = try await client.lookupAllRecords(
      recordNames: config.recordNames.map(RecordName.init(rawValue:)),
      desiredKeys: config.fields,
      database: config.base.database,
      batchSize: config.batchSize
    )

    let records = results.compactMap { result in
      if case .success(let record) = result { record } else { nil }
    }
    try await outputResults(records, format: config.output)
  }
}
