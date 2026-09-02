//
//  QueryConfig+Parsing.swift
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

extension QueryConfig {
  internal struct ParsedPagination {
    internal let limit: Int
    internal let offset: Int
    internal let fields: [String]?
    internal let continuationMarker: String?
    internal let output: OutputFormat
  }

  internal struct ParsedOptions {
    internal let zone: String
    internal let zoneOwner: String?
    internal let recordType: String
    internal let filters: [String]
    internal let sort: (field: String, order: SortOrder)?
    internal let pagination: ParsedPagination
  }

  internal static func parseAllOptions(
    _ configReader: MistDemoConfiguration
  ) throws -> ParsedOptions {
    let zone =
      configReader.read(MistDemoKeys.Query.zone)
    let zoneOwner = configReader.read(MistDemoKeys.Query.zoneOwner)
    let recordType =
      configReader.read(MistDemoKeys.Record.recordType)

    let filters = configReader.filterStrings(MistDemoKeys.Query.filter)

    let sortString = configReader.read(MistDemoKeys.Query.sort)
    let sort = try parseSortOption(sortString)

    let pagination = try parsePagination(configReader)

    return ParsedOptions(
      zone: zone,
      zoneOwner: zoneOwner,
      recordType: recordType,
      filters: filters,
      sort: sort,
      pagination: pagination
    )
  }

  private static func parsePagination(
    _ configReader: MistDemoConfiguration
  ) throws -> ParsedPagination {
    let limit =
      configReader.read(MistDemoKeys.Query.limit)
    guard
      limit >= MistDemoConstants.Limits.minQueryLimit,
      limit <= MistDemoConstants.Limits.maxQueryLimit
    else {
      throw QueryError.invalidLimit(limit)
    }

    let offset =
      configReader.read(MistDemoKeys.Query.offset)

    let fieldsString = configReader.read(MistDemoKeys.Record.fields)
    let fields = fieldsString?.split(separator: ",").map {
      String($0).trimmingCharacters(in: .whitespaces)
    }

    let continuationMarker = configReader.read(MistDemoKeys.Query.continuationMarker)

    let outputString =
      configReader.read(MistDemoKeys.Output.format)
    let output = OutputFormat(rawValue: outputString) ?? .json

    return ParsedPagination(
      limit: limit,
      offset: offset,
      fields: Array(fields ?? []),
      continuationMarker: continuationMarker,
      output: output
    )
  }

  private static func parseSortOption(
    _ sortString: String?
  ) throws -> (field: String, order: SortOrder)? {
    guard let sortString = sortString, !sortString.isEmpty else {
      return nil
    }

    let components = sortString.split(separator: ":", maxSplits: 1)
    guard components.count >= 1 else {
      return nil
    }

    let field = String(components[0]).trimmingCharacters(
      in: .whitespaces
    )
    let orderString =
      components.count > 1
      ? String(components[1]).trimmingCharacters(in: .whitespaces)
      : "asc"

    guard let order = SortOrder(rawValue: orderString.lowercased()) else {
      throw QueryError.invalidSortOrder(
        orderString,
        available: SortOrder.allCases.map(\.rawValue)
      )
    }

    return (field: field, order: order)
  }
}
