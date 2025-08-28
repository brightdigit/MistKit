//
//  CustomFieldValuePayload+Extensions.swift
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
