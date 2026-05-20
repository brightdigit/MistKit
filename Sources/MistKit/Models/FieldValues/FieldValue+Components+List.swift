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

/// List-value conversions for `FieldValue` ← `Components.Schemas` response types.
extension FieldValue {
  /// Initialize from list field value
  internal init(
    listValue: [Components.Schemas.ListValuePayload],
    fieldName: String
  ) throws {
    let convertedList = try listValue.map { try Self(listItem: $0, fieldName: fieldName) }
    self = .list(convertedList)
  }

  /// Initialize from individual list item
  internal init(
    listItem: Components.Schemas.ListValuePayload,
    fieldName: String
  ) throws {
    if let simpleValue = Self.makeSimpleListItem(from: listItem) {
      self = simpleValue
    } else if let complexValue = try Self.makeComplexListItem(from: listItem, fieldName: fieldName)
    {
      self = complexValue
    } else {
      try CloudKitError.reportConversionFailure(
        "Unmappable list item for field '\(fieldName)' (\(listItem))"
      )
    }
  }

  /// Initialize from nested list value (simplified for basic types)
  internal init(
    nestedListValue: [Components.Schemas.ListValuePayload],
    fieldName: String
  ) throws {
    let convertedNestedList = try nestedListValue.map {
      try Self(basicListItem: $0, fieldName: fieldName)
    }
    self = .list(convertedNestedList)
  }

  /// Initialize from basic list item types only
  internal init(
    basicListItem: Components.Schemas.ListValuePayload,
    fieldName: String
  ) throws {
    switch basicListItem {
    case .StringValue(let stringValue):
      self = .string(stringValue)
    case .Int64Value(let intValue):
      self = .int64(Int(intValue))
    case .DoubleValue(let doubleValue):
      self = .double(doubleValue)
    case .BytesValue(let bytesValue):
      self = .bytes(bytesValue)
    default:
      try CloudKitError.reportConversionFailure(
        "Unmappable nested list item for field '\(fieldName)' (\(basicListItem))"
      )
    }
  }

  private static func makeSimpleListItem(
    from listItem: Components.Schemas.ListValuePayload
  ) -> FieldValue? {
    if case .StringValue(let strVal) = listItem {
      return .string(strVal)
    }
    if case .Int64Value(let intVal) = listItem {
      return .int64(Int(intVal))
    }
    if case .DoubleValue(let dblVal) = listItem {
      return .double(dblVal)
    }
    if case .BytesValue(let bytesVal) = listItem {
      return .bytes(bytesVal)
    }
    if case .DateValue(let dateVal) = listItem {
      return .date(Date(timeIntervalSince1970: dateVal / 1_000))
    }
    return nil
  }

  private static func makeComplexListItem(
    from listItem: Components.Schemas.ListValuePayload,
    fieldName: String
  ) throws -> FieldValue? {
    if case .LocationValue(let locationValue) = listItem {
      return try Self(locationValue: locationValue, fieldName: fieldName)
    }
    if case .ReferenceValue(let referenceValue) = listItem {
      return try Self(referenceValue: referenceValue, fieldName: fieldName)
    }
    if case .AssetValue(let assetValue) = listItem {
      return Self(assetValue: assetValue)
    }
    if case .ListValue(let nestedList) = listItem {
      return try Self(nestedListValue: nestedList, fieldName: fieldName)
    }
    return nil
  }
}
