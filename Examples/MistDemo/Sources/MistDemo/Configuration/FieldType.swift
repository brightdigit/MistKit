//
//  FieldType.swift
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