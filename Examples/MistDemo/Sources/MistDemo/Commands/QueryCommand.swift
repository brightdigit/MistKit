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
    public typealias Config = QueryConfig
    public static let commandName = "query"
    public static let abstract = "Query records from CloudKit with filtering and sorting"
    public static let helpText = """
        QUERY - Query records from CloudKit

        USAGE:
            mistdemo query [options]

        OPTIONS:
            --record-type <type>       Record type to query (default: Note)
            --zone <zone>              Zone name (default: _defaultZone)
            --filter <filter>          Filter expression(s) (field:operator:value, use | to separate multiple)
            --sort <field:order>       Sort by field (order: asc/desc)
            --limit <count>            Maximum records to return (1-200)
            --fields <fields>          Comma-separated fields to include
            --output-format <format>   Output format: json, table, csv, yaml
        """
    
    private let config: QueryConfig
    
    public init(config: QueryConfig) {
        self.config = config
    }
    
    public func execute() async throws {
        do {
            // Create CloudKit client
            let client = try MistKitClientFactory.createForPublicDatabase(from: config.base)

            // Build filters
            // NOTE: Zone, offset, and continuation marker support require
            // enhancements to CloudKitService.queryRecords method (GitHub issues #145, #146)
            let recordInfos: [RecordInfo]
            if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                let filters: [QueryFilter]? = config.filters.isEmpty
                    ? nil
                    : try config.filters.map { try parseFilter($0) }
                recordInfos = try await client.queryRecords(
                    recordType: config.recordType,
                    filters: filters,
                    sortBy: nil,
                    limit: config.limit
                )
            } else {
                recordInfos = try await client.queryRecords(
                    recordType: config.recordType,
                    filters: nil,
                    sortBy: nil,
                    limit: config.limit
                )
            }

            // Format and output results
            try await outputResults(recordInfos, format: config.output)

        } catch {
            throw QueryError.operationFailed(error.localizedDescription)
        }
    }

    /// Parse a single filter expression "field:operator:value" into a QueryFilter
    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    private func parseFilter(_ filterString: String) throws -> QueryFilter {
        let components = filterString.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)

        guard components.count == 3 else {
            throw QueryError.invalidFilter(filterString, expected: "field:operator:value")
        }

        let field = String(components[0]).trimmingCharacters(in: .whitespaces)
        let operatorString = String(components[1]).trimmingCharacters(in: .whitespaces)
        let value = String(components[2])

        guard !field.isEmpty else {
            throw QueryError.emptyFieldName(filterString)
        }

        switch operatorString.lowercased() {
        case "eq", "equals", "==", "=":
            return .equals(field, inferFieldValue(value))
        case "ne", "not_equals", "!=":
            return .notEquals(field, inferFieldValue(value))
        case "gt", ">":
            return .greaterThan(field, inferFieldValue(value))
        case "gte", ">=":
            return .greaterThanOrEquals(field, inferFieldValue(value))
        case "lt", "<":
            return .lessThan(field, inferFieldValue(value))
        case "lte", "<=":
            return .lessThanOrEquals(field, inferFieldValue(value))
        case "contains", "like":
            return .containsAllTokens(field, value)
        case "begins_with", "starts_with":
            return .beginsWith(field, value)
        case "in":
            let values = value.split(separator: ",").map { inferFieldValue(String($0)) }
            return .in(field, values)
        case "not_in":
            let values = value.split(separator: ",").map { inferFieldValue(String($0)) }
            return .notIn(field, values)
        default:
            throw QueryError.unsupportedOperator(operatorString)
        }
    }

    /// Infer a FieldValue from a string, preferring Int64, then Double, then String
    private func inferFieldValue(_ string: String) -> FieldValue {
        if let i = Int64(string) { return .int64(Int(i)) }
        if let d = Double(string) { return .double(d) }
        return .string(string)
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

// QueryError is now defined in Errors/QueryError.swift