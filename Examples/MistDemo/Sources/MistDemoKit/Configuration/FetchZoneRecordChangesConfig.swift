//
//  FetchZoneRecordChangesConfig.swift
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
internal import Foundation

/// Configuration for the `fetch-zone-record-changes` command.
public struct FetchZoneRecordChangesConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The CloudKit zone names to fetch record changes from.
  public let zones: [String]
  /// The optional sync token applied to every requested zone.
  public let syncToken: String?
  /// Whether to fetch all changes via auto-pagination (per zone).
  public let fetchAll: Bool
  /// The optional limit on number of records to fetch per zone per page.
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
    zones: [String] = ["_defaultZone"],
    syncToken: String? = nil,
    fetchAll: Bool = false,
    limit: Int? = nil,
    desiredKeys: [String]? = nil,
    desiredRecordTypes: [String]? = nil,
    output: OutputFormat = .table
  ) {
    self.base = base
    self.zones = zones
    self.syncToken = syncToken
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

    let zonesString =
      configuration.string(forKey: "zone.names", default: "_defaultZone")
      ?? "_defaultZone"
    let zones = zonesString.split(separator: ",").map {
      $0.trimmingCharacters(in: .whitespaces)
    }

    let syncToken = configuration.string(forKey: "sync.token")
    let fetchAll =
      configuration.bool(forKey: "fetch.all", default: false)
    let limit = configuration.int(forKey: "limit")
    let desiredKeys = configuration.commaSeparatedList(
      forKey: MistDemoConstants.ConfigKeys.fields
    )
    let desiredRecordTypes = configuration.commaSeparatedList(
      forKey: MistDemoConstants.ConfigKeys.desiredRecordTypes
    )
    let outputString =
      configuration.string(forKey: "output.format", default: "table")
      ?? "table"
    let output = OutputFormat(rawValue: outputString) ?? .table

    self.init(
      base: baseConfig,
      zones: zones,
      syncToken: syncToken,
      fetchAll: fetchAll,
      limit: limit,
      desiredKeys: desiredKeys,
      desiredRecordTypes: desiredRecordTypes,
      output: output
    )
  }
}
