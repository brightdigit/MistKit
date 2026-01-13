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

/// Extension to convert OpenAPI Components.Schemas.FieldValue to MistKit FieldValue
extension FieldValue {
  /// Initialize from OpenAPI Components.Schemas.FieldValue
  internal init?(_ fieldData: Components.Schemas.FieldValue) {
    self.init(value: fieldData.value, fieldType: fieldData.type)
  }

  /// Initialize from field value and type
  private init?(
    value: CustomFieldValue.CustomFieldValuePayload,
    fieldType: CustomFieldValue.FieldTypePayload?
  ) {
    switch value {
    case .stringValue(let stringValue):
      self = .string(stringValue)
    case .int64Value(let intValue):
      self = .int64(intValue)
    case .doubleValue(let doubleValue):
      if fieldType == .timestamp {
        self = .date(Date(timeIntervalSince1970: doubleValue / 1_000))
      } else {
        self = .double(doubleValue)
      }
    case .booleanValue(let boolValue):
      self = .int64(boolValue ? 1 : 0)
    case .bytesValue(let bytesValue):
      self = .bytes(bytesValue)
    case .dateValue(let dateValue):
      self = .date(Date(timeIntervalSince1970: dateValue / 1_000))
    case .locationValue(let locationValue):
      guard let location = Self(locationValue: locationValue) else { return nil }
      self = location
    case .referenceValue(let referenceValue):
      self.init(referenceValue: referenceValue)
    case .assetValue(let assetValue):
      self.init(assetValue: assetValue)
    case .listValue(let listValue):
      self.init(listValue: listValue)
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
  private init(listValue: [CustomFieldValue.CustomFieldValuePayload]) {
    let convertedList = listValue.compactMap { Self(listItem: $0) }
    self = .list(convertedList)
  }

  /// Initialize from individual list item
  private init?(listItem: CustomFieldValue.CustomFieldValuePayload) {
    switch listItem {
    case .stringValue(let stringValue):
      self = .string(stringValue)
    case .int64Value(let intValue):
      self = .int64(intValue)
    case .doubleValue(let doubleValue):
      self = .double(doubleValue)
    case .booleanValue(let boolValue):
      self = .int64(boolValue ? 1 : 0)
    case .bytesValue(let bytesValue):
      self = .bytes(bytesValue)
    case .dateValue(let dateValue):
      self = .date(Date(timeIntervalSince1970: dateValue / 1_000))
    case .locationValue(let locationValue):
      guard let location = Self(locationValue: locationValue) else { return nil }
      self = location
    case .referenceValue(let referenceValue):
      self.init(referenceValue: referenceValue)
    case .assetValue(let assetValue):
      self.init(assetValue: assetValue)
    case .listValue(let nestedList):
      self.init(nestedListValue: nestedList)
    }
  }

  /// Initialize from nested list value (simplified for basic types)
  private init(nestedListValue: [CustomFieldValue.CustomFieldValuePayload]) {
    let convertedNestedList = nestedListValue.compactMap { Self(basicListItem: $0) }
    self = .list(convertedNestedList)
  }

  /// Initialize from basic list item types only
  private init?(basicListItem: CustomFieldValue.CustomFieldValuePayload) {
    switch basicListItem {
    case .stringValue(let stringValue):
      self = .string(stringValue)
    case .int64Value(let intValue):
      self = .int64(intValue)
    case .doubleValue(let doubleValue):
      self = .double(doubleValue)
    case .bytesValue(let bytesValue):
      self = .bytes(bytesValue)
    default:
      return nil
    }
  }
}
