//
//  FieldValueFormatter.swift
//  MistDemo
//
//  Created by Leo Dion on 7/9/25.
//

import Foundation
import MistKit

/// Utility for formatting FieldValue objects for display
struct FieldValueFormatter {
    
    /// Format FieldValue fields for display
    static func formatFields(_ fields: [String: FieldValue]) -> String {
        if fields.isEmpty {
            return "{}"
        }
        
        let formattedFields = fields.map { (key, value) in
            let valueString = formatFieldValue(value)
            return "\(key): \(valueString)"
        }.joined(separator: ", ")
        
        return "{\(formattedFields)}"
    }
    
    /// Extract the raw display string from a FieldValue without extra quoting.
    /// Used by formatters where the escaper handles quoting.
    static func displayString(_ value: FieldValue) -> String {
        switch value {
        case .string(let string):
            return string
        case .int64(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .bytes(let bytes):
            return bytes
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        case .location(let location):
            return "(\(location.latitude), \(location.longitude))"
        case .reference(let reference):
            return reference.recordName
        case .asset(let asset):
            return asset.downloadURL ?? "no URL"
        case .list(let values):
            let formattedValues = values.map { displayString($0) }.joined(separator: ", ")
            return "[\(formattedValues)]"
        }
    }

    /// Format a single FieldValue for display
    static func formatFieldValue(_ value: FieldValue) -> String {
        switch value {
        case .string(let string):
            return "\"\(string)\""
        case .int64(let int):
            return "\(int)"
        case .double(let double):
            return "\(double)"
        case .bytes(let bytes):
            return "bytes(\(bytes.count) chars, base64: \(bytes))"
        case .date(let date):
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return "date(\(formatter.string(from: date)))"
        case .location(let location):
            return "location(\(location.latitude), \(location.longitude))"
        case .reference(let reference):
            return "reference(\(reference.recordName))"
        case .asset(let asset):
            return "asset(\(asset.downloadURL ?? "no URL"))"
        case .list(let values):
            let formattedValues = values.map { formatFieldValue($0) }.joined(separator: ", ")
            return "[\(formattedValues)]"
        }
    }
}
