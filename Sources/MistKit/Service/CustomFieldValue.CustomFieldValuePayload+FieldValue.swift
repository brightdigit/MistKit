//
//  CustomFieldValue.CustomFieldValuePayload+FieldValue.swift
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

/// Extension to convert MistKit FieldValue to CustomFieldValue.CustomFieldValuePayload
extension CustomFieldValue.CustomFieldValuePayload {
  /// Initialize from MistKit FieldValue (for list nesting)
  internal init(_ fieldValue: FieldValue) {
    if let scalar = Self.makeScalarPayload(from: fieldValue) {
      self = scalar
    } else {
      self = Self.makeComplexPayload(from: fieldValue)
    }
  }

  /// Initialize from Location to payload value
  private init(location: FieldValue.Location) {
    self = .locationValue(
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

  /// Initialize from Reference to payload value
  private init(reference: FieldValue.Reference) {
    let action: Components.Schemas.ReferenceValue.actionPayload?
    switch reference.action {
    case .some(.deleteSelf):
      action = .DELETE_SELF
    case .some(.none):
      action = .NONE
    case nil:
      action = nil
    }
    self = .referenceValue(
      Components.Schemas.ReferenceValue(
        recordName: reference.recordName,
        action: action
      )
    )
  }

  /// Initialize from Asset to payload value
  private init(asset: FieldValue.Asset) {
    self = .assetValue(
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

  /// Initialize from basic FieldValue types to payload (for nested lists)
  private init(basicFieldValue: FieldValue) {
    switch basicFieldValue {
    case .string(let stringValue):
      self = .stringValue(stringValue)
    case .int64(let intValue):
      self = .int64Value(intValue)
    case .double(let doubleValue):
      self = .doubleValue(doubleValue)
    case .bytes(let bytesValue):
      self = .bytesValue(bytesValue)
    case .date(let dateValue):
      self = .dateValue(dateValue.timeIntervalSince1970 * 1_000)
    default:
      self = .stringValue("unsupported")
    }
  }

  private static func makeScalarPayload(from fieldValue: FieldValue) -> Self? {
    if case .string(let value) = fieldValue {
      return .stringValue(value)
    }
    if case .int64(let value) = fieldValue {
      return .int64Value(value)
    }
    if case .double(let value) = fieldValue {
      return .doubleValue(value)
    }
    if case .bytes(let value) = fieldValue {
      return .bytesValue(value)
    }
    if case .date(let value) = fieldValue {
      return .dateValue(value.timeIntervalSince1970 * 1_000)
    }
    return nil
  }

  private static func makeComplexPayload(from fieldValue: FieldValue) -> Self {
    switch fieldValue {
    case .location(let location):
      return Self(location: location)
    case .reference(let reference):
      return Self(reference: reference)
    case .asset(let asset):
      return Self(asset: asset)
    case .list(let nestedList):
      return .listValue(nestedList.map { Self(basicFieldValue: $0) })
    default:
      return .stringValue("")
    }
  }
}
