//
//  Components.Schemas.FieldValue+FieldValue.swift
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

/// Extension to convert MistKit FieldValue to OpenAPI Components.Schemas.FieldValue
extension Components.Schemas.FieldValue {
  /// Initialize from MistKit FieldValue
  internal init(_ fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self.init(value: .stringValue(value), type: .string)
    case .int64(let value):
      self.init(value: .int64Value(value), type: .int64)
    case .double(let value):
      self.init(value: .doubleValue(value), type: .double)
    case .boolean(let value):
      self.init(value: .booleanValue(value), type: .int64)
    case .bytes(let value):
      self.init(value: .bytesValue(value), type: .bytes)
    case .date(let value):
      let milliseconds = Int64(value.timeIntervalSince1970 * 1_000)
      self.init(value: .dateValue(Double(milliseconds)), type: .timestamp)
    case .location(let location):
      self = Self.fromLocation(location)
    case .reference(let reference):
      self = Self.fromReference(reference)
    case .asset(let asset):
      self = Self.fromAsset(asset)
    case .list(let list):
      self = Self.fromList(list)
    }
  }

  /// Convert Location to Components LocationValue
  private static func fromLocation(_ location: FieldValue.Location) -> Self {
    let locationValue = Components.Schemas.LocationValue(
      latitude: location.latitude,
      longitude: location.longitude,
      horizontalAccuracy: location.horizontalAccuracy,
      verticalAccuracy: location.verticalAccuracy,
      altitude: location.altitude,
      speed: location.speed,
      course: location.course,
      timestamp: location.timestamp.map { $0.timeIntervalSince1970 * 1_000 }
    )
    return Self(value: .locationValue(locationValue), type: .location)
  }

  /// Convert Reference to Components ReferenceValue
  private static func fromReference(_ reference: FieldValue.Reference) -> Self {
    let referenceValue = Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: reference.action.flatMap { .init(rawValue: $0) }
    )
    return Self(value: .referenceValue(referenceValue), type: .reference)
  }

  /// Convert Asset to Components AssetValue
  private static func fromAsset(_ asset: FieldValue.Asset) -> Self {
    let assetValue = Components.Schemas.AssetValue(
      fileChecksum: asset.fileChecksum,
      size: asset.size,
      referenceChecksum: asset.referenceChecksum,
      wrappingKey: asset.wrappingKey,
      receipt: asset.receipt,
      downloadURL: asset.downloadURL
    )
    return Self(value: .assetValue(assetValue), type: .asset)
  }

  /// Convert List to Components list value
  private static func fromList(_ list: [FieldValue]) -> Self {
    let listValues = list.map { CustomFieldValue.CustomFieldValuePayload($0) }
    return Self(value: .listValue(listValues), type: .list)
  }
}
