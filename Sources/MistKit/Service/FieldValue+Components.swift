//
//  FieldValue+Components.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

internal import Foundation

/// Extension to convert OpenAPI Components.Schemas.FieldValueResponse to MistKit FieldValue
extension FieldValue {
  /// Initialize from OpenAPI Components.Schemas.FieldValueResponse (from API responses)
  internal init?(_ fieldData: Components.Schemas.FieldValueResponse) {
    self.init(valuePayload: fieldData.value, typePayload: fieldData._type)
  }

  /// Initialize from field value and type
  private init?(
    valuePayload: Components.Schemas.FieldValueResponse.valuePayload,
    typePayload: Components.Schemas.FieldValueResponse._typePayload?
  ) {
    if let simpleValue = Self.makeSimpleFieldValue(from: valuePayload, type: typePayload) {
      self = simpleValue
    } else if let complexValue = Self.makeComplexFieldValue(from: valuePayload) {
      self = complexValue
    } else {
      return nil
    }
  }

  /// Initialize from location field value
  private init?(locationValue: Components.Schemas.LocationValue) {
    guard let latitude = locationValue.latitude,
      let longitude = locationValue.longitude
    else {
      return nil
    }

    let location = Location(
      latitude: latitude,
      longitude: longitude,
      horizontalAccuracy: locationValue.horizontalAccuracy,
      verticalAccuracy: locationValue.verticalAccuracy,
      altitude: locationValue.altitude,
      speed: locationValue.speed,
      course: locationValue.course,
      timestamp: locationValue.timestamp.map { Date(timeIntervalSince1970: $0 / 1_000) }
    )
    self = .location(location)
  }

  /// Initialize from reference field value
  private init(referenceValue: Components.Schemas.ReferenceValue) {
    let action: Reference.Action?
    switch referenceValue.action {
    case .DELETE_SELF:
      action = .deleteSelf
    case .NONE:
      action = Reference.Action.none
    case nil:
      action = nil
    }
    let reference = Reference(
      recordName: referenceValue.recordName ?? "",
      action: action
    )
    self = .reference(reference)
  }

  /// Initialize from asset field value
  private init(assetValue: Components.Schemas.AssetValue) {
    let asset = Asset(
      fileChecksum: assetValue.fileChecksum,
      size: assetValue.size,
      referenceChecksum: assetValue.referenceChecksum,
      wrappingKey: assetValue.wrappingKey,
      receipt: assetValue.receipt,
      downloadURL: assetValue.downloadURL
    )
    self = .asset(asset)
  }

  /// Initialize from list field value
  private init(listValue: [Components.Schemas.ListValuePayload]) {
    let convertedList = listValue.compactMap { Self(listItem: $0) }
    self = .list(convertedList)
  }

  /// Initialize from individual list item
  private init?(listItem: Components.Schemas.ListValuePayload) {
    if let simpleValue = Self.makeSimpleListItem(from: listItem) {
      self = simpleValue
    } else if let complexValue = Self.makeComplexListItem(from: listItem) {
      self = complexValue
    } else {
      return nil
    }
  }

  /// Initialize from nested list value (simplified for basic types)
  private init(nestedListValue: [Components.Schemas.ListValuePayload]) {
    let convertedNestedList = nestedListValue.compactMap { Self(basicListItem: $0) }
    self = .list(convertedNestedList)
  }

  /// Initialize from basic list item types only
  private init?(basicListItem: Components.Schemas.ListValuePayload) {
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
      return nil
    }
  }

  private static func makeSimpleFieldValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?
  ) -> FieldValue? {
    if case .StringValue(let strVal) = value {
      return .string(strVal)
    }
    if case .Int64Value(let intVal) = value {
      return .int64(Int(intVal))
    }
    if case .DoubleValue(let dblVal) = value {
      return fieldType == .TIMESTAMP
        ? .date(Date(timeIntervalSince1970: dblVal / 1_000))
        : .double(dblVal)
    }
    if case .BytesValue(let bytesVal) = value {
      return .bytes(bytesVal)
    }
    if case .DateValue(let dateVal) = value {
      return .date(Date(timeIntervalSince1970: dateVal / 1_000))
    }
    return nil
  }

  private static func makeComplexFieldValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload
  ) -> FieldValue? {
    if case .LocationValue(let locationValue) = value {
      return Self(locationValue: locationValue)
    }
    if case .ReferenceValue(let referenceValue) = value {
      return Self(referenceValue: referenceValue)
    }
    if case .AssetValue(let assetValue) = value {
      return Self(assetValue: assetValue)
    }
    if case .ListValue(let listValue) = value {
      return Self(listValue: listValue)
    }
    return nil
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
    from listItem: Components.Schemas.ListValuePayload
  ) -> FieldValue? {
    if case .LocationValue(let locationValue) = listItem {
      return Self(locationValue: locationValue)
    }
    if case .ReferenceValue(let referenceValue) = listItem {
      return Self(referenceValue: referenceValue)
    }
    if case .AssetValue(let assetValue) = listItem {
      return Self(assetValue: assetValue)
    }
    if case .ListValue(let nestedList) = listItem {
      return Self(nestedListValue: nestedList)
    }
    return nil
  }
}
