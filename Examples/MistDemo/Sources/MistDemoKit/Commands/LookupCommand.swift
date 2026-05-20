//
//  LookupCommand.swift
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

/// Command to look up records by name in CloudKit
public struct LookupCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = LookupConfig
  /// The command name.
  public static let commandName = "lookup"
  /// The command abstract.
  public static let abstract = "Look up records by name from CloudKit"
  /// The command help text.
  public static let helpText = """
    LOOKUP - Fetch records by name from CloudKit

    USAGE:
      mistdemo lookup --record-names <names> [options]

    REQUIRED:
      --api-token <token>          CloudKit API token
      --web-auth-token <token>     Web authentication token
      --record-names <names>       Comma-separated record names

    OPTIONS:
      --fields <field1,field2,...>  Restrict returned fields
      --output-format <format>     Output format

    EXAMPLES:
      mistdemo lookup --record-name my-note-123
      mistdemo lookup --record-names note-1,note-2
      mistdemo lookup --record-names note-1 --fields title

    NOTES:
      Records not found are omitted from the response.
      A warning is printed to stderr listing missing names.
    """

  private let config: LookupConfig

  /// Creates a new instance.
  public init(config: LookupConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      let client = try MistKitClientFactory.create(for: config.base)

      let results = try await client.lookupRecords(
        recordNames: config.recordNames,
        desiredKeys: config.fields,
        database: config.base.database
      )

      // A per-record lookup failure (e.g. NOT_FOUND) comes back as `.failure`.
      let records = results.compactMap(\.record)

      // Report missing names to stderr so a JSON/CSV/etc. stdout stream stays parseable
      let foundNames = Set(records.map(\.recordName))
      let missing = config.recordNames.filter { !foundNames.contains($0) }
      if !missing.isEmpty {
        let line =
          "Warning: \(missing.count) record(s) not found: \(missing.joined(separator: ", "))\n"
        FileHandle.standardError.write(Data(line.utf8))
      }

      try await outputResults(records, format: config.output)
    } catch let error as LookupError {
      throw error
    } catch {
      throw LookupError.operationFailed(error.localizedDescription)
    }
  }
}
