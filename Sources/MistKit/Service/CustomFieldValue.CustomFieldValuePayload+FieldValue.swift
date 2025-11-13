//
//  CustomFieldValue.CustomFieldValuePayload+FieldValue.swift
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

internal import Foundation

/// Extension to convert MistKit FieldValue to CustomFieldValue.CustomFieldValuePayload
extension CustomFieldValue.CustomFieldValuePayload {
  /// Initialize from MistKit FieldValue (for list nesting)
  internal init(_ fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self = .stringValue(value)
    case .int64(let value):
      self = .int64Value(value)
    case .double(let value):
      self = .doubleValue(value)
    case .boolean(let value):
      self = .booleanValue(value)
    case .bytes(let value):
      self = .bytesValue(value)
    case .date(let value):
      self = .dateValue(value.timeIntervalSince1970 * 1_000)
    case .location(let location):
      self = Self.fromLocation(location)
    case .reference(let reference):
      self = Self.fromReference(reference)
    case .asset(let asset):
      self = Self.fromAsset(asset)
    case .list(let nestedList):
      self = .listValue(nestedList.map { Self.fromBasicFieldValue($0) })
    }
  }

  /// Convert Location to payload value
  private static func fromLocation(_ location: FieldValue.Location) -> Self {
    .locationValue(
      Components.Schemas.LocationValue(
        latitude: location.latitude,
        longitude: location.longitude,
        horizontalAccuracy: location.horizontalAccuracy,
        verticalAccuracy: location.verticalAccuracy,
        altitude: location.altitude,
        speed: location.speed,
        course: location.course,
        timestamp: location.timestamp.map { $0.timeIntervalSince1970 * 1_000 }
      )
    )
  }

  /// Convert Reference to payload value
  private static func fromReference(_ reference: FieldValue.Reference) -> Self {
    let action: Components.Schemas.ReferenceValue.actionPayload?
    switch reference.action {
    case .some(.deleteSelf):
      action = .DELETE_SELF
    case .some(.none):
      action = .NONE
    case nil:
      action = nil
    }
    return .referenceValue(
      Components.Schemas.ReferenceValue(
        recordName: reference.recordName,
        action: action
      )
    )
  }

  /// Convert Asset to payload value
  private static func fromAsset(_ asset: FieldValue.Asset) -> Self {
    .assetValue(
      Components.Schemas.AssetValue(
        fileChecksum: asset.fileChecksum,
        size: asset.size,
        referenceChecksum: asset.referenceChecksum,
        wrappingKey: asset.wrappingKey,
        receipt: asset.receipt,
        downloadURL: asset.downloadURL
      )
    )
  }

  /// Convert basic FieldValue types to payload (for nested lists)
  private static func fromBasicFieldValue(_ item: FieldValue) -> Self {
    switch item {
    case .string(let stringValue):
      return .stringValue(stringValue)
    case .int64(let intValue):
      return .int64Value(intValue)
    case .double(let doubleValue):
      return .doubleValue(doubleValue)
    case .boolean(let boolValue):
      return .booleanValue(boolValue)
    case .bytes(let bytesValue):
      return .bytesValue(bytesValue)
    case .date(let dateValue):
      return .dateValue(dateValue.timeIntervalSince1970 * 1_000)
    default:
      return .stringValue("unsupported")
    }
  }
}
