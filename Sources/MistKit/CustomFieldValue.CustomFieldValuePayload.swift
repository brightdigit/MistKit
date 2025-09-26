//
//  CustomFieldValue.CustomFieldValuePayload.swift
//  MistKit
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

extension CustomFieldValue.CustomFieldValuePayload {
  /// Initialize from decoder
  public init(from decoder: any Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try Self.decodeBasicPayloadTypes(from: container) {
      self = value
      return
    }

    if let value = try Self.decodeComplexPayloadTypes(from: container) {
      self = value
      return
    }

    throw DecodingError.dataCorrupted(
      DecodingError.Context(
        codingPath: decoder.codingPath,
        debugDescription: "Could not decode FieldValuePayload"
      )
    )
  }

  /// Decode basic payload types (string, int64, double, boolean)
  private static func decodeBasicPayloadTypes(
    from container: any SingleValueDecodingContainer
  ) throws -> CustomFieldValue.CustomFieldValuePayload? {
    if let value = try? container.decode(String.self) {
      return .stringValue(value)
    }
    if let value = try? container.decode(Int.self) {
      return .int64Value(value)
    }
    if let value = try? container.decode(Double.self) {
      return .doubleValue(value)
    }
    if let value = try? container.decode(Bool.self) {
      return .booleanValue(value)
    }
    return nil
  }

  /// Decode complex payload types (asset, location, reference, list)
  private static func decodeComplexPayloadTypes(
    from container: any SingleValueDecodingContainer
  ) throws -> CustomFieldValue.CustomFieldValuePayload? {
    if let value = try? container.decode(Components.Schemas.AssetValue.self) {
      return .assetValue(value)
    }
    if let value = try? container.decode(Components.Schemas.LocationValue.self) {
      return .locationValue(value)
    }
    if let value = try? container.decode(Components.Schemas.ReferenceValue.self) {
      return .referenceValue(value)
    }
    if let value = try? container.decode([CustomFieldValue.CustomFieldValuePayload].self) {
      return .listValue(value)
    }
    return nil
  }

  /// Encode to encoder
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.singleValueContainer()
    try encodeValue(to: &container)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func encodeValue(to container: inout any SingleValueEncodingContainer) throws {
    switch self {
    case .stringValue(let val), .bytesValue(let val):
      try container.encode(val)
    case .int64Value(let val):
      try container.encode(val)
    case .booleanValue(let val):
      try container.encode(val)
    case .doubleValue(let val), .dateValue(let val):
      try encodeNumericValue(val, to: &container)
    case .locationValue(let val):
      try container.encode(val)
    case .referenceValue(let val):
      try container.encode(val)
    case .assetValue(let val):
      try container.encode(val)
    case .listValue(let val):
      try container.encode(val)
    }
  }

  private func encodeNumericValue<T: Encodable>(
    _ value: T, to container: inout any SingleValueEncodingContainer
  ) throws {
    try container.encode(value)
  }
}
