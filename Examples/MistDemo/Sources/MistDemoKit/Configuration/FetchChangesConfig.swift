//
//  FetchChangesConfig.swift
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

public import ConfigKeyKit

/// Configuration for fetch-changes command.
public struct FetchChangesConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The optional sync token for incremental changes.
  public let syncToken: String?
  /// The CloudKit zone name.
  public let zone: String
  /// Whether to fetch all changes via auto-pagination.
  public let fetchAll: Bool
  /// The optional limit on number of changes to fetch.
  public let limit: Int?
  /// The optional field names limiting the fields returned per record.
  public let desiredKeys: [String]?
  /// The optional record-type names limiting the change feed.
  public let desiredRecordTypes: [String]?
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    syncToken: String? = nil,
    zone: String = "_defaultZone",
    fetchAll: Bool = false,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    desiredRecordTypes: [String]? = nil,
    output: OutputFormat = .table
  ) {
    self.base = base
    self.syncToken = syncToken
    self.zone = zone
    self.fetchAll = fetchAll
    self.limit = limit
    self.desiredKeys = desiredKeys
    self.desiredRecordTypes = desiredRecordTypes
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let baseConfig: MistDemoConfig
    if let base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let syncToken = configuration.read(MistDemoKeys.Changes.syncToken)
    let zone =
      configuration.read(MistDemoKeys.Query.zone)
    let fetchAll =
      configuration.read(MistDemoKeys.Changes.fetchAll)
    let limit = configuration.read(MistDemoKeys.Query.optionalLimit)
    let desiredKeys = configuration.commaSeparatedList(MistDemoKeys.Record.fields)
    let desiredRecordTypes = configuration.commaSeparatedList(
      MistDemoKeys.Changes.desiredRecordTypes
    )
    let outputString =
      configuration.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .table

    self.init(
      base: baseConfig,
      syncToken: syncToken,
      zone: zone,
      fetchAll: fetchAll,
      limit: limit,
      desiredKeys: desiredKeys,
      desiredRecordTypes: desiredRecordTypes,
      output: output
    )
  }
}
