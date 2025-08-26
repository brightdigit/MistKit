//
//  CustomFieldValue.swift
//  MistKit
//
//  Created by Claude Code on 8/26/25.
//

import Foundation
import OpenAPIRuntime

/// Custom implementation of FieldValue with proper ASSETID handling
internal struct CustomFieldValue: Codable, Hashable, Sendable {
  let value: CustomFieldValuePayload
  let _type: FieldTypePayload?

  public enum FieldTypePayload: String, Codable, Hashable, Sendable, CaseIterable {
    case STRING = "STRING"
    case INT64 = "INT64"
    case DOUBLE = "DOUBLE"
    case BYTES = "BYTES"
    case REFERENCE = "REFERENCE"
    case ASSET = "ASSET"
    case ASSETID = "ASSETID"
    case LOCATION = "LOCATION"
    case TIMESTAMP = "TIMESTAMP"
    case LIST = "LIST"
  }

  public enum CustomFieldValuePayload: Codable, Hashable, Sendable {
    case StringValue(String)
    case Int64Value(Int64)
    case DoubleValue(Double)
    case BooleanValue(Bool)
    case BytesValue(String)
    case DateValue(Double)
    case LocationValue(Components.Schemas.LocationValue)
    case ReferenceValue(Components.Schemas.ReferenceValue)
    case AssetValue(Components.Schemas.AssetValue)
    case ListValue([CustomFieldValuePayload])
  }

  enum CodingKeys: String, CodingKey {
    case value
    case _type = "type"
  }

  // Convenience initializers for creating instances
  init(value: CustomFieldValuePayload, type: FieldTypePayload) {
    self.value = value
    self._type = type
  }

  init(stringValue: String) {
    self.value = .StringValue(stringValue)
    self._type = .STRING
  }

  init(int64Value: Int64) {
    self.value = .Int64Value(int64Value)
    self._type = .INT64
  }

  init(doubleValue: Double) {
    self.value = .DoubleValue(doubleValue)
    self._type = .DOUBLE
  }

  init(booleanValue: Bool) {
    self.value = .BooleanValue(booleanValue)
    self._type = .BYTES  // Boolean values are stored as bytes in CloudKit
  }

  init(dateValue: Double) {
    self.value = .DateValue(dateValue)
    self._type = .TIMESTAMP
  }

  init(locationValue: Components.Schemas.LocationValue) {
    self.value = .LocationValue(locationValue)
    self._type = .LOCATION
  }

  init(referenceValue: Components.Schemas.ReferenceValue) {
    self.value = .ReferenceValue(referenceValue)
    self._type = .REFERENCE
  }

  init(assetValue: Components.Schemas.AssetValue) {
    self.value = .AssetValue(assetValue)
    self._type = .ASSET
  }

  init(listValue: [CustomFieldValuePayload]) {
    self.value = .ListValue(listValue)
    self._type = .LIST
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let _type = try container.decodeIfPresent(FieldTypePayload.self, forKey: ._type)
    self._type = _type

    // Decode value based on the field type
    if let fieldType = _type {
      switch fieldType {
      case .STRING:
        let stringValue = try container.decode(String.self, forKey: .value)
        self.value = .StringValue(stringValue)

      case .INT64:
        let intValue = try container.decode(Int64.self, forKey: .value)
        self.value = .Int64Value(intValue)

      case .DOUBLE:
        let doubleValue = try container.decode(Double.self, forKey: .value)
        self.value = .DoubleValue(doubleValue)

      case .BYTES:
        let bytesValue = try container.decode(String.self, forKey: .value)
        self.value = .BytesValue(bytesValue)

      case .REFERENCE:
        let refValue = try container.decode(Components.Schemas.ReferenceValue.self, forKey: .value)
        self.value = .ReferenceValue(refValue)

      case .ASSET, .ASSETID:
        // Both ASSET and ASSETID decode as AssetValue
        let assetValue = try container.decode(Components.Schemas.AssetValue.self, forKey: .value)
        self.value = .AssetValue(assetValue)

      case .LOCATION:
        let locationValue = try container.decode(
          Components.Schemas.LocationValue.self, forKey: .value)
        self.value = .LocationValue(locationValue)

      case .TIMESTAMP:
        let dateValue = try container.decode(Double.self, forKey: .value)
        self.value = .DateValue(dateValue)

      case .LIST:
        let listValue = try container.decode([CustomFieldValuePayload].self, forKey: .value)
        self.value = .ListValue(listValue)
      }
    } else {
      // Fallback decoding without type information
      let valueContainer = try container.superDecoder(forKey: .value)
      self.value = try CustomFieldValuePayload(from: valueContainer)
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(_type, forKey: ._type)

    switch value {
    case .StringValue(let stringValue):
      try container.encode(stringValue, forKey: .value)
    case .Int64Value(let intValue):
      try container.encode(intValue, forKey: .value)
    case .DoubleValue(let doubleValue):
      try container.encode(doubleValue, forKey: .value)
    case .BooleanValue(let boolValue):
      try container.encode(boolValue, forKey: .value)
    case .BytesValue(let bytesValue):
      try container.encode(bytesValue, forKey: .value)
    case .DateValue(let dateValue):
      try container.encode(dateValue, forKey: .value)
    case .LocationValue(let locationValue):
      try container.encode(locationValue, forKey: .value)
    case .ReferenceValue(let refValue):
      try container.encode(refValue, forKey: .value)
    case .AssetValue(let assetValue):
      try container.encode(assetValue, forKey: .value)
    case .ListValue(let listValue):
      try container.encode(listValue, forKey: .value)
    }
  }
}
