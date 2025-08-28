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
  /// Field type payload for CloudKit fields
  public enum FieldTypePayload: String, Codable, Hashable, Sendable, CaseIterable {
    case string = "STRING"
    case int64 = "INT64"
    case double = "DOUBLE"
    case bytes = "BYTES"
    case reference = "REFERENCE"
    case asset = "ASSET"
    case assetid = "ASSETID"
    case location = "LOCATION"
    case timestamp = "TIMESTAMP"
    case list = "LIST"
  }

  /// Custom field value payload supporting various CloudKit types
  public enum CustomFieldValuePayload: Codable, Hashable, Sendable {
    case stringValue(String)
    case int64Value(Int64)
    case doubleValue(Double)
    case booleanValue(Bool)
    case bytesValue(String)
    case dateValue(Double)
    case locationValue(Components.Schemas.LocationValue)
    case referenceValue(Components.Schemas.ReferenceValue)
    case assetValue(Components.Schemas.AssetValue)
    case listValue([CustomFieldValuePayload])
  }

  internal enum CodingKeys: String, CodingKey {
    case value
    case type
  }

  /// The field value payload
  internal let value: CustomFieldValuePayload
  /// The field type
  internal let type: FieldTypePayload?

  /// Convenience initializers for creating instances
  internal init(value: CustomFieldValuePayload, type: FieldTypePayload) {
    self.value = value
    self.type = type
  }

  /// Initialize with string value
  internal init(stringValue: String) {
    self.value = .stringValue(stringValue)
    self.type = .string
  }

  /// Initialize with int64 value
  internal init(int64Value: Int64) {
    self.value = .int64Value(int64Value)
    self.type = .int64
  }

  /// Initialize with double value
  internal init(doubleValue: Double) {
    self.value = .doubleValue(doubleValue)
    self.type = .double
  }

  /// Initialize with boolean value
  internal init(booleanValue: Bool) {
    self.value = .booleanValue(booleanValue)
    self.type = .bytes  // Boolean values are stored as bytes in CloudKit
  }

  /// Initialize with date value
  internal init(dateValue: Double) {
    self.value = .dateValue(dateValue)
    self.type = .timestamp
  }

  /// Initialize with location value
  internal init(locationValue: Components.Schemas.LocationValue) {
    self.value = .locationValue(locationValue)
    self.type = .location
  }

  /// Initialize with reference value
  internal init(referenceValue: Components.Schemas.ReferenceValue) {
    self.value = .referenceValue(referenceValue)
    self.type = .reference
  }

  /// Initialize with asset value
  internal init(assetValue: Components.Schemas.AssetValue) {
    self.value = .assetValue(assetValue)
    self.type = .asset
  }

  /// Initialize with list value
  internal init(listValue: [CustomFieldValuePayload]) {
    self.value = .listValue(listValue)
    self.type = .list
  }

  internal init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let fieldType = try container.decodeIfPresent(FieldTypePayload.self, forKey: .type)
    self.type = fieldType

    // Decode value based on the field type
    if let fieldType = fieldType {
      switch fieldType {
      case .string:
        let stringValue = try container.decode(String.self, forKey: .value)
        self.value = .stringValue(stringValue)

      case .int64:
        let intValue = try container.decode(Int64.self, forKey: .value)
        self.value = .int64Value(intValue)

      case .double:
        let doubleValue = try container.decode(Double.self, forKey: .value)
        self.value = .doubleValue(doubleValue)

      case .bytes:
        let bytesValue = try container.decode(String.self, forKey: .value)
        self.value = .bytesValue(bytesValue)

      case .reference:
        let refValue = try container.decode(Components.Schemas.ReferenceValue.self, forKey: .value)
        self.value = .referenceValue(refValue)

      case .asset, .assetid:
        // Both ASSET and ASSETID decode as AssetValue
        let assetValue = try container.decode(Components.Schemas.AssetValue.self, forKey: .value)
        self.value = .assetValue(assetValue)

      case .location:
        let locationValue = try container.decode(
          Components.Schemas.LocationValue.self,
          forKey: .value
        )
        self.value = .locationValue(locationValue)

      case .timestamp:
        let dateValue = try container.decode(Double.self, forKey: .value)
        self.value = .dateValue(dateValue)

      case .list:
        let listValue = try container.decode([CustomFieldValuePayload].self, forKey: .value)
        self.value = .listValue(listValue)
      }
    } else {
      // Fallback decoding without type information
      let valueContainer = try container.superDecoder(forKey: .value)
      self.value = try CustomFieldValuePayload(from: valueContainer)
    }
  }

  internal func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(type, forKey: .type)

    switch value {
    case .stringValue(let stringValue):
      try container.encode(stringValue, forKey: .value)
    case .int64Value(let intValue):
      try container.encode(intValue, forKey: .value)
    case .doubleValue(let doubleValue):
      try container.encode(doubleValue, forKey: .value)
    case .booleanValue(let boolValue):
      try container.encode(boolValue, forKey: .value)
    case .bytesValue(let bytesValue):
      try container.encode(bytesValue, forKey: .value)
    case .dateValue(let dateValue):
      try container.encode(dateValue, forKey: .value)
    case .locationValue(let locationValue):
      try container.encode(locationValue, forKey: .value)
    case .referenceValue(let refValue):
      try container.encode(refValue, forKey: .value)
    case .assetValue(let assetValue):
      try container.encode(assetValue, forKey: .value)
    case .listValue(let listValue):
      try container.encode(listValue, forKey: .value)
    }
  }
}
