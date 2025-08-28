//
//  RecordInfo.swift
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

/// Record information from CloudKit
public struct RecordInfo: Encodable {
  /// The record name
  public let recordName: String
  /// The record type
  public let recordType: String
  /// The record fields
  public let fields: [String: FieldValue]

  internal init(from record: Components.Schemas.Record) {
    self.recordName = record.recordName ?? "Unknown"
    self.recordType = record.recordType ?? "Unknown"

    // Convert fields to FieldValue representation
    var convertedFields: [String: FieldValue] = [:]

    if let fieldsPayload = record.fields {
      for (fieldName, fieldData) in fieldsPayload.additionalProperties {
        if let fieldValue = Self.convertToFieldValue(fieldData) {
          convertedFields[fieldName] = fieldValue
        }
      }
    }

    self.fields = convertedFields
  }

  /// Convert a CloudKit field value to FieldValue
  private static func convertToFieldValue(_ fieldData: Components.Schemas.FieldValue) -> FieldValue?
  {
    logFieldTypeConversion(fieldData)

    let convertedValue = convertFieldValueByType(fieldData.value, fieldType: fieldData.type)

    if convertedValue == nil {
      logUnhandledFieldValue(fieldData)
    }

    return convertedValue
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
      return convertDoubleFieldValue(doubleValue, fieldType: fieldType)
    case .booleanValue(let boolValue):
      return .boolean(boolValue)
    case .bytesValue(let bytesValue):
      return .bytes(bytesValue)
    case .dateValue(let dateValue):
      return convertDateFieldValue(dateValue)
    case .locationValue(let locationValue):
      return convertLocationFieldValue(locationValue)
    case .referenceValue(let referenceValue):
      return convertReferenceFieldValue(referenceValue)
    case .assetValue(let assetValue):
      return convertAssetFieldValue(assetValue)
    case .listValue(let listValue):
      return convertListFieldValue(listValue)
    }
  }

  /// Log field type conversion for debugging
  private static func logFieldTypeConversion(_ fieldData: Components.Schemas.FieldValue) {
    #if DEBUG
      if let fieldType = fieldData.type {
        print("🔍 Converting field with type: \(fieldType)")
        if fieldType == .assetid || fieldType == .asset {
          print("📁 Asset field detected, value type: \(fieldData.value)")
        }
      }
    #endif
  }

  /// Log unhandled field value for debugging
  private static func logUnhandledFieldValue(_ fieldData: Components.Schemas.FieldValue) {
    #if DEBUG
      print(
        "⚠️  Unhandled field value type: \(fieldData.value) with fieldType: \(fieldData.type?.rawValue ?? "nil")"
      )
    #endif
  }

  /// Convert double field value, handling timestamp conversion
  private static func convertDoubleFieldValue(
    _ doubleValue: Double, fieldType: CustomFieldValue.FieldTypePayload?
  ) -> FieldValue {
    if let fieldType = fieldType, fieldType == .timestamp {
      let date = Date(timeIntervalSince1970: doubleValue / 1_000)
      return .date(date)
    }
    return .double(doubleValue)
  }

  /// Convert date field value
  private static func convertDateFieldValue(_ dateValue: Double) -> FieldValue {
    let date = Date(timeIntervalSince1970: dateValue / 1_000)
    return .date(date)
  }

  /// Convert location field value
  private static func convertLocationFieldValue(
    _ locationValue: Components.Schemas.LocationValue
  ) -> FieldValue {
    let location = FieldValue.Location(
      latitude: locationValue.latitude ?? 0.0,
      longitude: locationValue.longitude ?? 0.0,
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
  ) -> FieldValue {
    let reference = FieldValue.Reference(
      recordName: referenceValue.recordName ?? "",
      action: referenceValue.action?.rawValue
    )
    return .reference(reference)
  }

  /// Convert asset field value
  private static func convertAssetFieldValue(
    _ assetValue: Components.Schemas.AssetValue
  ) -> FieldValue {
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
    let convertedList = listValue.compactMap { listItem in
      convertListItem(listItem)
    }
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
    case .dateValue(let dateValue):
      return convertDateFieldValue(dateValue)
    case .locationValue(let locationValue):
      return convertLocationFieldValue(locationValue)
    case .referenceValue(let referenceValue):
      return convertReferenceFieldValue(referenceValue)
    case .assetValue(let assetValue):
      return convertAssetFieldValue(assetValue)
    case .listValue(let nestedList):
      return convertNestedListValue(nestedList)
    }
  }

  /// Convert nested list value (simplified for basic types)
  private static func convertNestedListValue(
    _ nestedList: [CustomFieldValue.CustomFieldValuePayload]
  ) -> FieldValue {
    let nestedConvertedList = nestedList.compactMap { nestedItem in
      convertBasicListItem(nestedItem)
    }
    return .list(nestedConvertedList)
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
    default:
      return nil
    }
  }
}
