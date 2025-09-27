//
//  RecordFieldConverter.swift
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

/// Utilities for converting CloudKit field values to FieldValue types
internal enum RecordFieldConverter {
  /// Convert a CloudKit field value to FieldValue
  internal static func convertToFieldValue(_ fieldData: Components.Schemas.FieldValue)
    -> FieldValue?
  {
    convertFieldValueByType(fieldData.value, fieldType: fieldData.type)
  }

  /// Convert field value based on its type
  private static func convertFieldValueByType(
    _ value: CustomFieldValue.CustomFieldValuePayload,
    fieldType: CustomFieldValue.FieldTypePayload?
  ) -> FieldValue? {
    switch value {
    case .stringValue(let stringValue):
      return .string(stringValue)
    case .int64Value(let intValue):
      return .int64(intValue)
    case .doubleValue(let doubleValue):
      return fieldType == .timestamp
        ? .date(Date(timeIntervalSince1970: doubleValue / 1_000)) : .double(doubleValue)
    case .booleanValue(let boolValue):
      return .boolean(boolValue)
    case .bytesValue(let bytesValue):
      return .bytes(bytesValue)
    default:
      return convertComplexFieldValue(value)
    }
  }

  /// Convert complex field types (date, location, reference, asset, list)
  private static func convertComplexFieldValue(
    _ value: CustomFieldValue.CustomFieldValuePayload
  ) -> FieldValue? {
    switch value {
    case .dateValue(let dateValue):
      return .date(Date(timeIntervalSince1970: dateValue / 1_000))
    case .locationValue(let locationValue):
      return convertLocationFieldValue(locationValue)
    case .referenceValue(let referenceValue):
      return convertReferenceFieldValue(referenceValue)
    case .assetValue(let assetValue):
      return convertAssetFieldValue(assetValue)
    case .listValue(let listValue):
      return convertListFieldValue(listValue)
    default:
      return nil
    }
  }

  /// Convert location field value
  private static func convertLocationFieldValue(
    _ locationValue: Components.Schemas.LocationValue
  ) -> FieldValue? {
    guard let latitude = locationValue.latitude,
      let longitude = locationValue.longitude
    else {
      return nil
    }

    let location = FieldValue.Location(
      latitude: latitude,
      longitude: longitude,
      horizontalAccuracy: locationValue.horizontalAccuracy,
      verticalAccuracy: locationValue.verticalAccuracy,
      altitude: locationValue.altitude,
      speed: locationValue.speed,
      course: locationValue.course,
      timestamp: locationValue.timestamp.map { Date(timeIntervalSince1970: $0 / 1_000) }
    )
    return .location(location)
  }

  /// Convert reference field value
  private static func convertReferenceFieldValue(
    _ referenceValue: Components.Schemas.ReferenceValue
  ) -> FieldValue? {
    let reference = FieldValue.Reference(
      recordName: referenceValue.recordName ?? "",
      action: referenceValue.action?.rawValue
    )
    return .reference(reference)
  }

  /// Convert asset field value
  private static func convertAssetFieldValue(
    _ assetValue: Components.Schemas.AssetValue
  ) -> FieldValue? {
    let asset = FieldValue.Asset(
      fileChecksum: assetValue.fileChecksum,
      size: assetValue.size,
      referenceChecksum: assetValue.referenceChecksum,
      wrappingKey: assetValue.wrappingKey,
      receipt: assetValue.receipt,
      downloadURL: assetValue.downloadURL
    )
    return .asset(asset)
  }

  /// Convert list field value
  private static func convertListFieldValue(
    _ listValue: [CustomFieldValue.CustomFieldValuePayload]
  ) -> FieldValue {
    let convertedList = listValue.compactMap { convertListItem($0) }
    return .list(convertedList)
  }

  /// Convert individual list item
  private static func convertListItem(_ listItem: CustomFieldValue.CustomFieldValuePayload)
    -> FieldValue?
  {
    switch listItem {
    case .stringValue(let stringValue):
      return .string(stringValue)
    case .int64Value(let intValue):
      return .int64(intValue)
    case .doubleValue(let doubleValue):
      return .double(doubleValue)
    case .booleanValue(let boolValue):
      return .boolean(boolValue)
    case .bytesValue(let bytesValue):
      return .bytes(bytesValue)
    default:
      return convertComplexListItem(listItem)
    }
  }

  /// Convert complex list item types
  private static func convertComplexListItem(
    _ listItem: CustomFieldValue.CustomFieldValuePayload
  ) -> FieldValue? {
    switch listItem {
    case .dateValue(let dateValue):
      return .date(Date(timeIntervalSince1970: dateValue / 1_000))
    case .locationValue(let locationValue):
      return convertLocationFieldValue(locationValue)
    case .referenceValue(let referenceValue):
      return convertReferenceFieldValue(referenceValue)
    case .assetValue(let assetValue):
      return convertAssetFieldValue(assetValue)
    case .listValue(let nestedList):
      return convertNestedListValue(nestedList)
    default:
      return nil
    }
  }

  /// Convert nested list value (simplified for basic types)
  private static func convertNestedListValue(
    _ nestedList: [CustomFieldValue.CustomFieldValuePayload]
  ) -> FieldValue {
    let convertedNestedList = nestedList.compactMap { convertBasicListItem($0) }
    return .list(convertedNestedList)
  }

  /// Convert basic list item types only
  private static func convertBasicListItem(_ nestedItem: CustomFieldValue.CustomFieldValuePayload)
    -> FieldValue?
  {
    switch nestedItem {
    case .stringValue(let stringValue):
      return .string(stringValue)
    case .int64Value(let intValue):
      return .int64(intValue)
    case .doubleValue(let doubleValue):
      return .double(doubleValue)
    case .booleanValue(let boolValue):
      return .boolean(boolValue)
    case .bytesValue(let bytesValue):
      return .bytes(bytesValue)
    default:
      return nil
    }
  }
}
