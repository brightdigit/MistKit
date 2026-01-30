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

public import Foundation
public import MistKit

/// Command to query Note records from CloudKit with filtering and sorting
public struct QueryCommand: MistDemoCommand, OutputFormatting {
    public static let commandName = "query"
    public static let abstract = "Query records from CloudKit with filtering and sorting"
    public static let helpText = """
        QUERY - Query records from CloudKit

        USAGE:
            mistdemo query [options]

        OPTIONS:
            --record-type <type>       Record type to query (default: Note)
            --zone <zone>              Zone name (default: _defaultZone)
            --filter <filter>          Filter expression (field:operator:value)
            --sort <field:order>       Sort by field (order: asc/desc)
            --limit <count>            Maximum records to return (1-200)
            --fields <fields>          Comma-separated fields to include
            --output-format <format>   Output format: json, table, csv, yaml
        """
    
    private let config: QueryConfig
    
    public init(config: QueryConfig) {
        self.config = config
    }
    
    /// Initialize from command line arguments using Swift Configuration
    public init() throws {
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
        
        self.config = QueryConfig(
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
    
    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.create(from: config.base)
            
            // Build query parameters
            var queryParams: [String: Any] = [:]
            
            // Add filters
            if !config.filters.isEmpty {
                let filterQueries = try parseFilters(config.filters)
                queryParams["filters"] = filterQueries
            }
            
            // Add sort
            if let sort = config.sort {
                queryParams["sort"] = [["fieldName": sort.field, "order": sort.order.rawValue]]
            }
            
            // Execute query
            // NOTE: Zone, offset, and continuation marker support require
            // enhancements to CloudKitService.queryRecords method (GitHub issues #145, #146)
            let recordInfos = try await client.queryRecords(
                recordType: config.recordType,
                filters: nil, // TODO: Pass parsed filters once supported
                sortBy: nil, // TODO: Pass parsed sort once supported
                limit: config.limit
            )
            
            // Note: Field filtering is applied during output formatting
            // to work around RecordInfo's immutable structure
            let filteredRecords = recordInfos
            
            // Format and output results
            try await outputResults(filteredRecords, format: config.output)
            
        } catch {
            throw QueryError.operationFailed(error.localizedDescription)
        }
    }
    
    /// Parse sort option from string format "field:order"
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
    
    /// Parse filter expressions
    private func parseFilters(_ filters: [String]) throws -> [[String: Any]] {
        return try filters.map { filterString in
            try parseFilter(filterString)
        }
    }
    
    /// Parse a single filter expression "field:operator:value"
    private func parseFilter(_ filterString: String) throws -> [String: Any] {
        let components = filterString.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        
        guard components.count == 3 else {
            throw QueryError.invalidFilter(filterString, expected: "field:operator:value")
        }
        
        let field = String(components[0]).trimmingCharacters(in: .whitespaces)
        let operatorString = String(components[1]).trimmingCharacters(in: .whitespaces)
        let value = String(components[2]) // Don't trim value as it may contain meaningful whitespace
        
        guard !field.isEmpty else {
            throw QueryError.emptyFieldName(filterString)
        }
        
        let cloudKitOperator = try mapToCloudKitOperator(operatorString)
        
        return [
            "fieldName": field,
            "comparator": cloudKitOperator,
            "fieldValue": ["value": value]
        ]
    }
    
    /// Map string operators to CloudKit operators
    private func mapToCloudKitOperator(_ operator: String) throws -> String {
        switch `operator`.lowercased() {
        case "eq", "equals", "==", "=":
            return "EQUALS"
        case "ne", "not_equals", "!=":
            return "NOT_EQUALS"
        case "gt", ">":
            return "GREATER_THAN"
        case "gte", ">=":
            return "GREATER_THAN_OR_EQUALS"
        case "lt", "<":
            return "LESS_THAN"
        case "lte", "<=":
            return "LESS_THAN_OR_EQUALS"
        case "contains", "like":
            return "CONTAINS"
        case "begins_with", "starts_with":
            return "BEGINS_WITH"
        case "in":
            return "IN"
        case "not_in":
            return "NOT_IN"
        default:
            throw QueryError.unsupportedOperator(`operator`)
        }
    }
    
    /// Check if a field should be included based on field filter
    private func shouldIncludeField(_ fieldName: String, fields: [String]?) -> Bool {
        guard let fields = fields, !fields.isEmpty else {
            return true // Include all fields if no filter specified
        }
        
        return fields.contains { requestedField in
            fieldName.lowercased() == requestedField.lowercased()
        }
    }
}

/// Errors specific to query command
public enum QueryError: Error, LocalizedError {
    case invalidLimit(Int)
    case invalidFilter(String, expected: String)
    case emptyFieldName(String)
    case invalidSortOrder(String, available: [String])
    case unsupportedOperator(String)
    case operationFailed(String)
    
    public var errorDescription: String? {
        switch self {
        case .invalidLimit(let limit):
            return String(format: MistDemoConstants.Messages.invalidLimit, limit, MistDemoConstants.Limits.minQueryLimit, MistDemoConstants.Limits.maxQueryLimit)
        case .invalidFilter(let filter, let expected):
            return "Invalid filter '\(filter)'. Expected format: \(expected)"
        case .emptyFieldName(let filter):
            return "Empty field name in filter '\(filter)'"
        case .invalidSortOrder(let order, let available):
            return "Invalid sort order '\(order)'. Available orders: \(available.joined(separator: ", "))"
        case .unsupportedOperator(let op):
            return "Unsupported filter operator '\(op)'. Supported: eq, ne, gt, gte, lt, lte, contains, begins_with, in, not_in"
        case .operationFailed(let message):
            return "Query operation failed: \(message)"
        }
    }
}