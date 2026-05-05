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

import Foundation
import MistKit

/// Command to look up records by name in CloudKit
public struct LookupCommand: MistDemoCommand, OutputFormatting {
  public typealias Config = LookupConfig
  public static let commandName = "lookup"
  public static let abstract = "Look up records by name from CloudKit"
  public static let helpText = """
    LOOKUP - Fetch one or more records by name from CloudKit

    USAGE:
        mistdemo lookup --record-names <name1,name2,...> [options]

    REQUIRED:
        --api-token <token>            CloudKit API token
        --web-auth-token <token>       Web authentication token
        --record-names <names>         Comma-separated record names
                                       (or use --record-name for one)

    OPTIONS:
        --fields <field1,field2,...>   Restrict the returned fields
        --output-format <format>       Output format: json, table, csv, yaml

    EXAMPLES:

      1. Look up a single record:
         mistdemo lookup --record-name my-note-123

      2. Look up multiple records:
         mistdemo lookup --record-names note-1,note-2,note-3

      3. Restrict returned fields:
         mistdemo lookup --record-names note-1,note-2 --fields title,priority

    NOTES:
      • Records that aren't found are silently omitted from the response.
        A warning is printed to stderr listing the missing names.
    """

  private let config: LookupConfig

  public init(config: LookupConfig) {
    self.config = config
  }

  public func execute() async throws {
    do {
      let client = try MistKitClientFactory.create(for: config.base)

      let records = try await client.lookupRecords(
        recordNames: config.recordNames,
        desiredKeys: config.fields
      )

      // Report missing names to stderr so a JSON/CSV/etc. stdout stream stays parseable
      let foundNames = Set(records.compactMap { $0.recordName })
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
