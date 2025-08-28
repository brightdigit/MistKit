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
    let value = fieldData.value

    #if DEBUG
      if let fieldType = fieldData.type {
        print("🔍 Converting field with type: \(fieldType)")
        if fieldType == .assetid || fieldType == .asset {
          print("📁 Asset field detected, value type: \(value)")
        }
      }
    #endif

    switch value {
    case .stringValue(let stringValue):
      return .string(stringValue)
    case .int64Value(let intValue):
      return .int64(intValue)
    case .doubleValue(let doubleValue):
      // Check the type to determine if it's a date or double
      if let fieldType = fieldData.type {
        switch fieldType {
        case .timestamp:
          // Convert milliseconds to Date
          let date = Date(timeIntervalSince1970: doubleValue / 1_000)
          return .date(date)
        default:
          return .double(doubleValue)
        }
      } else {
        return .double(doubleValue)
      }
    case .booleanValue(let boolValue):
      return .boolean(boolValue)
    case .bytesValue(let bytesValue):
      return .bytes(bytesValue)
    case .dateValue(let dateValue):
      // Convert milliseconds to Date
      let date = Date(timeIntervalSince1970: dateValue / 1_000)
      return .date(date)
    case .locationValue(let locationValue):
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
    case .referenceValue(let referenceValue):
      let reference = FieldValue.Reference(
        recordName: referenceValue.recordName ?? "",
        action: referenceValue.action?.rawValue
      )
      return .reference(reference)
    case .assetValue(let assetValue):
      let asset = FieldValue.Asset(
        fileChecksum: assetValue.fileChecksum,
        size: assetValue.size,
        referenceChecksum: assetValue.referenceChecksum,
        wrappingKey: assetValue.wrappingKey,
        receipt: assetValue.receipt,
        downloadURL: assetValue.downloadURL
      )
      return .asset(asset)
    case .listValue(let listValue):
      // Convert list items to FieldValue array
      let convertedList = listValue.compactMap { listItem in
        // Handle the recursive list structure properly
        switch listItem {
        case .stringValue(let stringValue):
          return FieldValue.string(stringValue)
        case .int64Value(let intValue):
          return FieldValue.int64(intValue)
        case .doubleValue(let doubleValue):
          return FieldValue.double(doubleValue)
        case .booleanValue(let boolValue):
          return FieldValue.boolean(boolValue)
        case .bytesValue(let bytesValue):
          return FieldValue.bytes(bytesValue)
        case .dateValue(let dateValue):
          let date = Date(timeIntervalSince1970: dateValue / 1_000)
          return FieldValue.date(date)
        case .locationValue(let locationValue):
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
          return FieldValue.location(location)
        case .referenceValue(let refValue):
          let reference = FieldValue.Reference(
            recordName: refValue.recordName ?? "",
            action: refValue.action?.rawValue
          )
          return FieldValue.reference(reference)
        case .assetValue(let assetValue):
          let asset = FieldValue.Asset(
            fileChecksum: assetValue.fileChecksum,
            size: assetValue.size,
            referenceChecksum: assetValue.referenceChecksum,
            wrappingKey: assetValue.wrappingKey,
            receipt: assetValue.receipt,
            downloadURL: assetValue.downloadURL
          )
          return FieldValue.asset(asset)
        case .listValue(let nestedList):
          // Recursively convert nested lists
          let nestedConvertedList = nestedList.compactMap { nestedItem in
            // For simplicity, we'll handle basic types in nested lists
            switch nestedItem {
            case .stringValue(let stringValue):
              return FieldValue.string(stringValue)
            case .int64Value(let intValue):
              return FieldValue.int64(intValue)
            case .doubleValue(let doubleValue):
              return FieldValue.double(doubleValue)
            case .booleanValue(let boolValue):
              return FieldValue.boolean(boolValue)
            default:
              // For complex nested types, return nil for now
              return nil
            }
          }
          return FieldValue.list(nestedConvertedList)
        }
      }
      return .list(convertedList)
    }

    #if DEBUG
      print(
        "⚠️  Unhandled field value type: \(value) with fieldType: \(fieldData.type?.rawValue ?? "nil")"
      )
    #endif
    return nil
  }
}
