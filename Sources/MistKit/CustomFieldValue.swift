//
//  CustomFieldValue.swift
//  PackageDSLKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation
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

  private static let fieldTypeDecoders:
    [FieldTypePayload: @Sendable (KeyedDecodingContainer<CodingKeys>) throws ->
      CustomFieldValuePayload] = [
        .string: { .stringValue(try $0.decode(String.self, forKey: .value)) },
        .int64: { .int64Value(try $0.decode(Int64.self, forKey: .value)) },
        .double: { .doubleValue(try $0.decode(Double.self, forKey: .value)) },
        .bytes: { .bytesValue(try $0.decode(String.self, forKey: .value)) },
        .reference: {
          .referenceValue(try $0.decode(Components.Schemas.ReferenceValue.self, forKey: .value))
        },
        .asset: { .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value)) },
        .assetid: {
          .assetValue(try $0.decode(Components.Schemas.AssetValue.self, forKey: .value))
        },
        .location: {
          .locationValue(try $0.decode(Components.Schemas.LocationValue.self, forKey: .value))
        },
        .timestamp: { .dateValue(try $0.decode(Double.self, forKey: .value)) },
        .list: { .listValue(try $0.decode([CustomFieldValuePayload].self, forKey: .value)) },
      ]

  private static let defaultDecoder:
    @Sendable (KeyedDecodingContainer<CodingKeys>) throws -> CustomFieldValuePayload = {
      .stringValue(try $0.decode(String.self, forKey: .value))
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

    if let fieldType = fieldType {
      self.value = try Self.decodeTypedValue(from: container, type: fieldType)
    } else {
      self.value = try Self.decodeFallbackValue(from: container)
    }
  }

  private static func decodeTypedValue(
    from container: KeyedDecodingContainer<CodingKeys>,
    type fieldType: FieldTypePayload
  ) throws -> CustomFieldValuePayload {
    let decoder = fieldTypeDecoders[fieldType] ?? defaultDecoder
    return try decoder(container)
  }

  private static func decodeFallbackValue(
    from container: KeyedDecodingContainer<CodingKeys>
  ) throws -> CustomFieldValuePayload {
    let valueContainer = try container.superDecoder(forKey: .value)
    return try CustomFieldValuePayload(from: valueContainer)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func encodeValue(
    _ value: CustomFieldValuePayload,
    to container: inout KeyedEncodingContainer<CodingKeys>
  ) throws {
    switch value {
    case .stringValue(let val), .bytesValue(let val):
      try container.encode(val, forKey: .value)
    case .int64Value(let val):
      try container.encode(val, forKey: .value)
    case .doubleValue(let val):
      try container.encode(val, forKey: .value)
    case .booleanValue(let val):
      try container.encode(val, forKey: .value)
    case .dateValue(let val):
      try container.encode(val, forKey: .value)
    case .locationValue(let val):
      try container.encode(val, forKey: .value)
    case .referenceValue(let val):
      try container.encode(val, forKey: .value)
    case .assetValue(let val):
      try container.encode(val, forKey: .value)
    case .listValue(let val):
      try container.encode(val, forKey: .value)
    }
  }

  internal func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(type, forKey: .type)
    try Self.encodeValue(value, to: &container)
  }
}
