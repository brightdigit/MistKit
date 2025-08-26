//
//  CustomFieldValuePayload+Extensions.swift
//  MistKit
//
//  Created by Claude Code on 8/26/25.
//

import Foundation

extension CustomFieldValue.CustomFieldValuePayload {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        
        // Try to decode different types in order
        if let value = try? container.decode(String.self) {
            self = .StringValue(value)
        } else if let value = try? container.decode(Int64.self) {
            self = .Int64Value(value)
        } else if let value = try? container.decode(Double.self) {
            self = .DoubleValue(value)
        } else if let value = try? container.decode(Bool.self) {
            self = .BooleanValue(value)
        } else if let value = try? container.decode(Components.Schemas.AssetValue.self) {
            self = .AssetValue(value)
        } else if let value = try? container.decode(Components.Schemas.LocationValue.self) {
            self = .LocationValue(value)
        } else if let value = try? container.decode(Components.Schemas.ReferenceValue.self) {
            self = .ReferenceValue(value)
        } else if let value = try? container.decode([CustomFieldValue.CustomFieldValuePayload].self) {
            self = .ListValue(value)
        } else {
            throw DecodingError.dataCorrupted(
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Could not decode FieldValuePayload"
                )
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        
        switch self {
        case .StringValue(let value):
            try container.encode(value)
        case .Int64Value(let value):
            try container.encode(value)
        case .DoubleValue(let value):
            try container.encode(value)
        case .BooleanValue(let value):
            try container.encode(value)
        case .BytesValue(let value):
            try container.encode(value)
        case .DateValue(let value):
            try container.encode(value)
        case .LocationValue(let value):
            try container.encode(value)
        case .ReferenceValue(let value):
            try container.encode(value)
        case .AssetValue(let value):
            try container.encode(value)
        case .ListValue(let value):
            try container.encode(value)
        }
    }
}
