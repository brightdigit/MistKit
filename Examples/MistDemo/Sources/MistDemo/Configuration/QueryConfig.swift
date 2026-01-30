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

public import Foundation
public import MistKit
public import ConfigKeyKit

/// Configuration for query command
public struct QueryConfig: Sendable, ConfigurationParseable {
    public let base: MistDemoConfig
    public let zone: String
    public let recordType: String
    public let filters: [String]
    public let sort: (field: String, order: SortOrder)?
    public let limit: Int
    public let offset: Int
    public let fields: [String]?
    public let continuationMarker: String?
    public let output: OutputFormat
    
    public init(
        base: MistDemoConfig,
        zone: String = "_defaultZone",
        recordType: String = "Note",
        filters: [String] = [],
        sort: (field: String, order: SortOrder)? = nil,
        limit: Int = 20,
        offset: Int = 0,
        fields: [String]? = nil,
        continuationMarker: String? = nil,
        output: OutputFormat = .json
    ) {
        self.base = base
        self.zone = zone
        self.recordType = recordType
        self.filters = filters
        self.sort = sort
        self.limit = limit
        self.offset = offset
        self.fields = fields
        self.continuationMarker = continuationMarker
        self.output = output
    }
    
    /// Parse configuration from command line arguments
    public init() async throws {
        let configReader = try MistDemoConfiguration()
        let baseConfig = try MistDemoConfig()
        
        // Parse query-specific options
        let zone = configReader.string(forKey: MistDemoConstants.ConfigKeys.zone, default: MistDemoConstants.Defaults.zone) ?? MistDemoConstants.Defaults.zone
        let recordType = configReader.string(forKey: MistDemoConstants.ConfigKeys.recordType, default: MistDemoConstants.Defaults.recordType) ?? MistDemoConstants.Defaults.recordType
        
        // Parse filters (can be multiple)
        let filtersString = configReader.string(forKey: MistDemoConstants.ConfigKeys.filter)
        let filters = filtersString?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) } ?? []
        
        // Parse sort option
        let sortString = configReader.string(forKey: MistDemoConstants.ConfigKeys.sort)
        let sort = try Self.parseSortOption(sortString)
        
        // Parse limits and pagination
        let limit = configReader.int(forKey: MistDemoConstants.ConfigKeys.limit, default: MistDemoConstants.Defaults.queryLimit) ?? MistDemoConstants.Defaults.queryLimit
        guard limit >= MistDemoConstants.Limits.minQueryLimit && limit <= MistDemoConstants.Limits.maxQueryLimit else {
            throw QueryError.invalidLimit(limit)
        }
        
        let offset = configReader.int(forKey: "offset", default: 0) ?? 0
        
        // Parse fields filter
        let fieldsString = configReader.string(forKey: MistDemoConstants.ConfigKeys.fields)
        let fields = fieldsString?.split(separator: ",").map { String($0).trimmingCharacters(in: .whitespaces) }
        
        // Parse continuation marker
        let continuationMarker = configReader.string(forKey: "continuation.marker")
        
        // Parse output format
        let outputString = configReader.string(forKey: MistDemoConstants.ConfigKeys.outputFormat, default: MistDemoConstants.Defaults.outputFormat) ?? MistDemoConstants.Defaults.outputFormat
        let output = OutputFormat(rawValue: outputString) ?? .json
        
        self.init(
            base: baseConfig,
            zone: zone,
            recordType: recordType,
            filters: filters,
            sort: sort,
            limit: limit,
            offset: offset,
            fields: Array(fields ?? []),
            continuationMarker: continuationMarker,
            output: output
        )
    }
    
    private static func parseSortOption(_ sortString: String?) throws -> (field: String, order: SortOrder)? {
        guard let sortString = sortString, !sortString.isEmpty else { return nil }
        
        let components = sortString.split(separator: ":", maxSplits: 1)
        guard components.count >= 1 else { return nil }
        
        let field = String(components[0]).trimmingCharacters(in: .whitespaces)
        let orderString = components.count > 1 ? String(components[1]).trimmingCharacters(in: .whitespaces) : "asc"
        
        guard let order = SortOrder(rawValue: orderString.lowercased()) else {
            throw QueryError.invalidSortOrder(orderString, available: SortOrder.allCases.map(\.rawValue))
        }
        
        return (field: field, order: order)
    }
}