//
//  FieldValue+Components+List.swift
//  MistKit
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

internal import Foundation
internal import MistKitOpenAPI

// swiftlint:disable file_length
/// Homogeneous list-value conversions for `FieldValue` ← `Components.Schemas` response types.
extension FieldValue {
  /// Initialize from a CloudKit list payload.
  /// When `elementKind` is set (from a `*_LIST` response tag), every element must match that
  /// kind or conversion throws ``ConversionError/typeValueMismatch``. When `elementKind` is
  /// `nil` (untagged list), the kind is inferred from the first element and remaining elements
  /// must match; an empty untagged list becomes `.string(.list([]))`.
  internal init(
    listValue: [Components.Schemas.ListValuePayload],
    elementKind: ListElementKind?,
    fieldName: String
  ) throws(ConversionError) {
    let kind: ListElementKind
    if let elementKind {
      kind = elementKind
    } else if let first = listValue.first {
      kind = try Self.inferredListElementKind(from: first, fieldName: fieldName)
    } else {
      // Empty untagged list: domain needs an element kind; STRING_LIST is the live default
      // for empty typed lists and matches `.string(.list([]))` (issue #481).
      self = .string(.list([]))
      return
    }
    self = try Self.makeHomogeneousList(
      from: listValue,
      kind: kind,
      fieldName: fieldName
    )
  }

  // Infer the list element kind from a single untagged payload (first-match wire shape).
  // swiftlint:disable:next cyclomatic_complexity
  private static func inferredListElementKind(
    from item: Components.Schemas.ListValuePayload,
    fieldName: String
  ) throws(ConversionError) -> ListElementKind {
    switch item {
    case .StringValue:
      return .string
    case .Int64Value:
      return .int64
    case .DoubleValue:
      return .double
    case .BytesValue:
      return .bytes
    case .DateValue:
      return .date
    case .LocationValue:
      return .location
    case .ReferenceValue:
      return .reference
    case .AssetValue:
      return .asset
    case .ListValue:
      let failure = ConversionError.unmappableListItem(fieldName: fieldName, item: "\(item)")
      try failure.reportAndThrow()
    }
  }

  // swiftlint:disable:next cyclomatic_complexity function_body_length
  private static func makeHomogeneousList(
    from listValue: [Components.Schemas.ListValuePayload],
    kind: ListElementKind,
    fieldName: String
  ) throws(ConversionError) -> FieldValue {
    // Manual loops (not `map`) so typed throws stay `ConversionError`.
    switch kind {
    case .string:
      var elements: [String] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireStringElement(item, fieldName: fieldName, declaredType: "STRING_LIST")
        )
      }
      return .string(.list(elements))
    case .int64:
      var elements: [Int] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireInt64Element(item, fieldName: fieldName, declaredType: "INT64_LIST")
        )
      }
      return .int64(.list(elements))
    case .double:
      var elements: [Double] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireDoubleElement(item, fieldName: fieldName, declaredType: "DOUBLE_LIST")
        )
      }
      return .double(.list(elements))
    case .bytes:
      var elements: [Data] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireBytesElement(item, fieldName: fieldName, declaredType: "BYTES_LIST")
        )
      }
      return .bytes(.list(elements))
    case .date:
      var elements: [Date] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireDateElement(item, fieldName: fieldName, declaredType: "TIMESTAMP_LIST")
        )
      }
      return .date(.list(elements))
    case .location:
      var elements: [Location] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireLocationElement(item, fieldName: fieldName, declaredType: "LOCATION_LIST")
        )
      }
      return .location(.list(elements))
    case .reference:
      var elements: [Reference] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireReferenceElement(item, fieldName: fieldName, declaredType: "REFERENCE_LIST")
        )
      }
      return .reference(.list(elements))
    case .asset:
      var elements: [Asset] = []
      elements.reserveCapacity(listValue.count)
      for item in listValue {
        elements.append(
          try requireAssetElement(item, fieldName: fieldName, declaredType: "ASSET_LIST")
        )
      }
      return .asset(.list(elements))
    }
  }

  private static func requireStringElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> String {
    guard case .StringValue(let value) = item else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return value
  }

  private static func requireInt64Element(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Int {
    guard case .Int64Value(let value) = item else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return Int(value)
  }

  private static func requireDoubleElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Double {
    switch item {
    case .DoubleValue(let value):
      return value
    case .Int64Value(let value):
      return Double(value)
    default:
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
  }

  private static func requireBytesElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Data {
    let string: String
    switch item {
    case .BytesValue(let value), .StringValue(let value):
      string = value
    default:
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return try dataFromBase64(string, fieldName: fieldName, declaredType: declaredType)
  }

  private static func requireDateElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Date {
    let milliseconds: Double
    switch item {
    case .DateValue(let value):
      milliseconds = value
    case .Int64Value(let value):
      milliseconds = Double(value)
    case .DoubleValue(let value):
      milliseconds = value
    default:
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return Date(timeIntervalSince1970: milliseconds / 1_000)
  }

  private static func requireLocationElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Location {
    guard case .LocationValue(let locationValue) = item else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    guard case .location(.value(let location)) = FieldValue(locationValue: locationValue) else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return location
  }

  private static func requireReferenceElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Reference {
    guard case .ReferenceValue(let referenceValue) = item else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    guard case .reference(.value(let reference)) = FieldValue(referenceValue: referenceValue)
    else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return reference
  }

  private static func requireAssetElement(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Asset {
    guard case .AssetValue(let assetValue) = item else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    guard case .asset(.value(let asset)) = FieldValue(assetValue: assetValue) else {
      try reportListElementMismatch(item, fieldName: fieldName, declaredType: declaredType)
    }
    return asset
  }

  private static func reportListElementMismatch(
    _ item: Components.Schemas.ListValuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Never {
    let failure = ConversionError.typeValueMismatch(
      fieldName: fieldName,
      declaredType: declaredType,
      value: "\(item)"
    )
    try failure.reportAndThrow()
  }
}
// swiftlint:enable file_length
