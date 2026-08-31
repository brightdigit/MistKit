//
//  QueryConfig.swift
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
public import MistKit

/// Configuration for query command.
public struct QueryConfig: Sendable, ConfigurationParseable {
  /// The configuration reader type.
  public typealias ConfigReader = MistDemoConfiguration
  /// The base configuration type.
  public typealias BaseConfig = MistDemoConfig

  /// The base MistDemo configuration.
  public let base: MistDemoConfig
  /// The CloudKit zone name.
  public let zone: String
  /// The optional zone owner (ownerName for shared zones).
  public let zoneOwner: String?
  /// The CloudKit record type.
  public let recordType: String
  /// The filter expressions.
  public let filters: [String]
  /// The optional sort field and order.
  public let sort: (field: String, order: SortOrder)?
  /// The maximum number of records to return.
  public let limit: Int
  /// The result offset for pagination.
  public let offset: Int
  /// The optional field names to include in the response.
  public let fields: [String]?
  /// The optional continuation marker for pagination.
  public let continuationMarker: String?
  /// Whether to query across all zones rather than a single zone.
  public let zoneWide: Bool?
  /// Whether numeric field values are returned as strings.
  public let numbersAsStrings: Bool?
  /// The output format.
  public let output: OutputFormat

  /// Creates a new instance.
  public init(
    base: MistDemoConfig,
    zone: String = "_defaultZone",
    zoneOwner: String? = nil,
    recordType: String = "Note",
    filters: [String] = [],
    sort: (field: String, order: SortOrder)? = nil,
    limit: Int = 20,
    offset: Int = 0,
    fields: [String]? = nil,
    continuationMarker: String? = nil,
    zoneWide: Bool? = nil,
    numbersAsStrings: Bool? = nil,
    output: OutputFormat = .json
  ) {
    self.base = base
    self.zone = zone
    self.zoneOwner = zoneOwner
    self.recordType = recordType
    self.filters = filters
    self.sort = sort
    self.limit = limit
    self.offset = offset
    self.fields = fields
    self.continuationMarker = continuationMarker
    self.zoneWide = zoneWide
    self.numbersAsStrings = numbersAsStrings
    self.output = output
  }

  /// Parse configuration from command line arguments.
  public init(
    configuration: MistDemoConfiguration,
    base: MistDemoConfig?
  ) async throws {
    let configReader = configuration
    let baseConfig: MistDemoConfig
    if let base = base {
      baseConfig = base
    } else {
      baseConfig = try await MistDemoConfig(
        configuration: configuration,
        base: nil
      )
    }

    let parsed = try Self.parseAllOptions(configReader)

    self.init(
      base: baseConfig,
      zone: parsed.zone,
      zoneOwner: parsed.zoneOwner,
      recordType: parsed.recordType,
      filters: parsed.filters,
      sort: parsed.sort,
      limit: parsed.pagination.limit,
      offset: parsed.pagination.offset,
      fields: parsed.pagination.fields,
      continuationMarker: parsed.pagination.continuationMarker,
      zoneWide: configReader.read(MistDemoKeys.Query.zoneWide),
      numbersAsStrings: configReader.read(MistDemoKeys.Record.numbersAsStrings),
      output: parsed.pagination.output
    )
  }
}
