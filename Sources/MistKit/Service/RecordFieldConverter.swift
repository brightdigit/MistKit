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

  /// Convert a FieldValue to CloudKit Components field value (for writing)
  internal static func toComponentsFieldValue(_ fieldValue: FieldValue) -> Components.Schemas.FieldValue {
    switch fieldValue {
    case .string(let value):
      return Components.Schemas.FieldValue(value: .stringValue(value), type: .string)
    case .int64(let value):
      return Components.Schemas.FieldValue(value: .int64Value(value), type: nil)
    case .double(let value):
      return Components.Schemas.FieldValue(value: .doubleValue(value), type: nil)
    case .boolean(let value):
      return Components.Schemas.FieldValue(value: .booleanValue(value), type: nil)
    case .bytes(let value):
      return Components.Schemas.FieldValue(value: .bytesValue(value), type: .bytes)
    case .date(let value):
      return Components.Schemas.FieldValue(value: .dateValue(value.timeIntervalSince1970 * 1000), type: .timestamp)
    case .location(let location):
      return convertLocationToComponents(location)
    case .reference(let reference):
      return convertReferenceToComponents(reference)
    case .asset(let asset):
      return convertAssetToComponents(asset)
    case .list(let list):
      return convertListToComponents(list)
    }
  }

  /// Convert Location to Components LocationValue
  private static func convertLocationToComponents(
    _ location: FieldValue.Location
  ) -> Components.Schemas.FieldValue {
    let locationValue = Components.Schemas.LocationValue(
      latitude: location.latitude,
      longitude: location.longitude,
      horizontalAccuracy: location.horizontalAccuracy,
      verticalAccuracy: location.verticalAccuracy,
      altitude: location.altitude,
      speed: location.speed,
      course: location.course,
      timestamp: location.timestamp.map { $0.timeIntervalSince1970 * 1000 }
    )
    return Components.Schemas.FieldValue(value: .locationValue(locationValue), type: .location)
  }

  /// Convert Reference to Components ReferenceValue
  private static func convertReferenceToComponents(
    _ reference: FieldValue.Reference
  ) -> Components.Schemas.FieldValue {
    let referenceValue = Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: reference.action.flatMap { .init(rawValue: $0) }
    )
    return Components.Schemas.FieldValue(value: .referenceValue(referenceValue), type: .reference)
  }

  /// Convert Asset to Components AssetValue
  private static func convertAssetToComponents(
    _ asset: FieldValue.Asset
  ) -> Components.Schemas.FieldValue {
    let assetValue = Components.Schemas.AssetValue(
      fileChecksum: asset.fileChecksum,
      size: asset.size,
      referenceChecksum: asset.referenceChecksum,
      wrappingKey: asset.wrappingKey,
      receipt: asset.receipt,
      downloadURL: asset.downloadURL
    )
    return Components.Schemas.FieldValue(value: .assetValue(assetValue), type: .asset)
  }

  /// Convert List to Components list value
  private static func convertListToComponents(
    _ list: [FieldValue]
  ) -> Components.Schemas.FieldValue {
    let listValues: [CustomFieldValue.CustomFieldValuePayload] = list.map { item in
      switch item {
      case .string(let value):
        return .stringValue(value)
      case .int64(let value):
        return .int64Value(value)
      case .double(let value):
        return .doubleValue(value)
      case .boolean(let value):
        return .booleanValue(value)
      case .bytes(let value):
        return .bytesValue(value)
      case .date(let value):
        return .dateValue(value.timeIntervalSince1970 * 1000)
      case .location(let location):
        return .locationValue(Components.Schemas.LocationValue(
          latitude: location.latitude,
          longitude: location.longitude,
          horizontalAccuracy: location.horizontalAccuracy,
          verticalAccuracy: location.verticalAccuracy,
          altitude: location.altitude,
          speed: location.speed,
          course: location.course,
          timestamp: location.timestamp.map { $0.timeIntervalSince1970 * 1000 }
        ))
      case .reference(let reference):
        return .referenceValue(Components.Schemas.ReferenceValue(
          recordName: reference.recordName,
          action: reference.action.flatMap { .init(rawValue: $0) }
        ))
      case .asset(let asset):
        return .assetValue(Components.Schemas.AssetValue(
          fileChecksum: asset.fileChecksum,
          size: asset.size,
          referenceChecksum: asset.referenceChecksum,
          wrappingKey: asset.wrappingKey,
          receipt: asset.receipt,
          downloadURL: asset.downloadURL
        ))
      case .list(let nestedList):
        // Nested lists - recursive conversion
        return .listValue(nestedList.map { nestedItem in
          // For simplicity, only support basic types in nested lists
          switch nestedItem {
          case .string(let v): return .stringValue(v)
          case .int64(let v): return .int64Value(v)
          case .double(let v): return .doubleValue(v)
          case .boolean(let v): return .booleanValue(v)
          case .bytes(let v): return .bytesValue(v)
          case .date(let v): return .dateValue(v.timeIntervalSince1970 * 1000)
          default: return .stringValue("unsupported")
          }
        })
      }
    }
    return Components.Schemas.FieldValue(value: .listValue(listValues), type: .list)
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
