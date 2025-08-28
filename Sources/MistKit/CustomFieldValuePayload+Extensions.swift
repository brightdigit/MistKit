//
//  CustomFieldValuePayload+Extensions.swift
//  MistKit
//
//  Created by Claude Code on 8/26/25.
//

import Foundation

extension CustomFieldValue.CustomFieldValuePayload {
  /// Initialize from decoder
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    // Try to decode different types in order
    if let value = try? container.decode(String.self) {
      self = .stringValue(value)
    } else if let value = try? container.decode(Int64.self) {
      self = .int64Value(value)
    } else if let value = try? container.decode(Double.self) {
      self = .doubleValue(value)
    } else if let value = try? container.decode(Bool.self) {
      self = .booleanValue(value)
    } else if let value = try? container.decode(Components.Schemas.AssetValue.self) {
      self = .assetValue(value)
    } else if let value = try? container.decode(Components.Schemas.LocationValue.self) {
      self = .locationValue(value)
    } else if let value = try? container.decode(Components.Schemas.ReferenceValue.self) {
      self = .referenceValue(value)
    } else if let value = try? container.decode([CustomFieldValue.CustomFieldValuePayload].self) {
      self = .listValue(value)
    } else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Could not decode FieldValuePayload"
        )
      )
    }
  }

  /// Encode to encoder
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch self {
    case .stringValue(let value):
      try container.encode(value)
    case .int64Value(let value):
      try container.encode(value)
    case .doubleValue(let value):
      try container.encode(value)
    case .booleanValue(let value):
      try container.encode(value)
    case .bytesValue(let value):
      try container.encode(value)
    case .dateValue(let value):
      try container.encode(value)
    case .locationValue(let value):
      try container.encode(value)
    case .referenceValue(let value):
      try container.encode(value)
    case .assetValue(let value):
      try container.encode(value)
    case .listValue(let value):
      try container.encode(value)
    }
  }
}
