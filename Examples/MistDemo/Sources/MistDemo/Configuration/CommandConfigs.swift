//
//  CommandConfigs.swift
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

/// Configuration for auth-token command
public struct AuthTokenConfig: Sendable {
    public let apiToken: String
    public let port: Int
    public let host: String
    public let noBrowser: Bool
    
    public init(apiToken: String, port: Int = 8080, host: String = "127.0.0.1", noBrowser: Bool = false) {
        self.apiToken = apiToken
        self.port = port
        self.host = host
        self.noBrowser = noBrowser
    }
}

/// Configuration for current-user command
public struct CurrentUserConfig: Sendable {
    public let base: MistDemoConfig
    public let fields: [String]?
    public let output: OutputFormat
    
    public init(base: MistDemoConfig, fields: [String]? = nil, output: OutputFormat = .json) {
        self.base = base
        self.fields = fields
        self.output = output
    }
}

/// Sort order for query operations
public enum SortOrder: String, CaseIterable, Sendable {
    case ascending = "asc"
    case descending = "desc"
}

/// Configuration for query command
public struct QueryConfig: Sendable {
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
}

/// Configuration for create command
public struct CreateConfig: Sendable {
    public let base: MistDemoConfig
    public let zone: String
    public let recordType: String
    public let recordName: String?
    public let fields: [Field]
    public let output: OutputFormat
    
    public init(
        base: MistDemoConfig,
        zone: String = "_defaultZone",
        recordType: String = "Note",
        recordName: String? = nil,
        fields: [Field] = [],
        output: OutputFormat = .json
    ) {
        self.base = base
        self.zone = zone
        self.recordType = recordType
        self.recordName = recordName
        self.fields = fields
        self.output = output
    }
}


/// Field definition for create operations
public struct Field: Sendable {
    public let name: String
    public let type: FieldType
    public let value: String
    
    public init(name: String, type: FieldType, value: String) {
        self.name = name
        self.type = type
        self.value = value
    }
    
    /// Parse a field from string format "name:type:value"
    public static func parse(_ input: String) throws -> Field {
        let components = input.split(separator: ":", maxSplits: 2, omittingEmptySubsequences: false)
        
        guard components.count == 3 else {
            throw FieldParsingError.invalidFormat(input, expected: "name:type:value")
        }
        
        let name = String(components[0]).trimmingCharacters(in: .whitespaces)
        let typeString = String(components[1]).trimmingCharacters(in: .whitespaces)
        let value = String(components[2]) // Don't trim value as it may contain meaningful whitespace
        
        guard !name.isEmpty else {
            throw FieldParsingError.emptyFieldName(input)
        }
        
        guard let type = FieldType(rawValue: typeString.lowercased()) else {
            throw FieldParsingError.unknownFieldType(typeString, available: FieldType.allCases.map(\.rawValue))
        }
        
        return Field(name: name, type: type, value: value)
    }
    
    /// Parse multiple fields from an array of strings
    public static func parseFields(_ inputs: [String]) throws -> [Field] {
        return try inputs.map { try parse($0) }
    }
}

/// Supported field types for CloudKit records
public enum FieldType: String, CaseIterable, Sendable {
    case string
    case int64
    case double
    case timestamp
    case asset
    case location
    case reference
    case bytes
    
    /// Convert field value to appropriate CloudKit field value
    public func convertValue(_ stringValue: String) throws -> Any {
        switch self {
        case .string:
            return stringValue
        case .int64:
            guard let intValue = Int64(stringValue) else {
                throw FieldParsingError.invalidValueForType(stringValue, type: self)
            }
            return intValue
        case .double:
            guard let doubleValue = Double(stringValue) else {
                throw FieldParsingError.invalidValueForType(stringValue, type: self)
            }
            return doubleValue
        case .timestamp:
            // Try parsing as ISO 8601 first, then as timestamp
            if let date = ISO8601DateFormatter().date(from: stringValue) {
                return date
            } else if let timestamp = Double(stringValue) {
                return Date(timeIntervalSince1970: timestamp)
            } else {
                throw FieldParsingError.invalidValueForType(stringValue, type: self)
            }
        case .asset, .location, .reference, .bytes:
            // These require more complex parsing - implement later
            throw FieldParsingError.unsupportedFieldType(self)
        }
    }
}

/// Errors that can occur during field parsing
public enum FieldParsingError: Error, LocalizedError {
    case invalidFormat(String, expected: String)
    case emptyFieldName(String)
    case unknownFieldType(String, available: [String])
    case invalidValueForType(String, type: FieldType)
    case unsupportedFieldType(FieldType)
    
    public var errorDescription: String? {
        switch self {
        case .invalidFormat(let input, let expected):
            return "Invalid field format '\(input)'. Expected format: \(expected)"
        case .emptyFieldName(let input):
            return "Empty field name in '\(input)'"
        case .unknownFieldType(let type, let available):
            return "Unknown field type '\(type)'. Available types: \(available.joined(separator: ", "))"
        case .invalidValueForType(let value, let type):
            return "Invalid value '\(value)' for field type '\(type.rawValue)'"
        case .unsupportedFieldType(let type):
            return "Field type '\(type.rawValue)' is not yet supported"
        }
    }
}