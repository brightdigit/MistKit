//
//  QueryCommand.swift
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

/// Command to query Note records from CloudKit with filtering and sorting
public struct QueryCommand: MistDemoCommand, OutputFormatting {
  /// The configuration type.
  public typealias Config = QueryConfig
  /// The command name.
  public static let commandName = "query"
  /// The command abstract.
  public static let abstract =
    "Query records from CloudKit with filtering and sorting"
  /// The command help text.
  public static let helpText = """
    QUERY - Query records from CloudKit

    USAGE:
      mistdemo query [options]

    OPTIONS:
      --record-type <type>     Record type (default: Note)
      --filter <filter>        Filter: field:operator:value
      --sort <field:order>     Sort (asc/desc)
      --limit <count>          Max records (1-200)
      --fields <fields>        Comma-separated fields
      --output-format <format> Output format
    """

  private let config: QueryConfig

  /// Creates a new instance.
  public init(config: QueryConfig) {
    self.config = config
  }

  /// Executes the command.
  public func execute() async throws {
    do {
      // Create CloudKit client
      let client = try MistKitClientFactory.create(for: config.base)

      // Build filters
      // NOTE: Zone, offset, and continuation marker support require
      // enhancements to CloudKitService.queryRecords method (GitHub issues #145, #146)
      let filters: [QueryFilter]? =
        config.filters.isEmpty
        ? nil
        : try config.filters.map { try Self.parseFilter($0) }
      let recordInfos = try await client.queryRecords(
        recordType: config.recordType,
        filters: filters,
        sortBy: nil,
        limit: config.limit,
        database: config.base.database
      )

      // Format and output results
      try await outputResults(recordInfos, format: config.output)
    } catch {
      throw QueryError.operationFailed(error.localizedDescription)
    }
  }
}

// QueryError is now defined in Errors/QueryError.swift
