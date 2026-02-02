//
//  Components+FieldValue.swift
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

/// Extension to convert MistKit FieldValue to OpenAPI Components.Schemas.FieldValue
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Components.Schemas.FieldValue {
  /// Initialize from MistKit FieldValue
  internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self.init(value: .stringValue(value), type: nil)
    case .int64(let value):
      self.init(value: .int64Value(value), type: nil)
    case .double(let value):
      self.init(value: .doubleValue(value), type: nil)
    case .bytes(let value):
      self.init(value: .bytesValue(value), type: nil)
    case .date(let value):
      let milliseconds = Int64(value.timeIntervalSince1970 * 1_000)
      self.init(value: .dateValue(Double(milliseconds)), type: nil)
    case .location(let location):
      self.init(location: location)
    case .reference(let reference):
      self.init(reference: reference)
    case .asset(let asset):
      self.init(asset: asset)
    case .list(let list):
      self.init(list: list)
    }
  }

  /// Initialize from Location to Components LocationValue
  private init(location: FieldValue.Location) {
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
    self.init(value: .locationValue(locationValue), type: nil)
  }

  /// Initialize from Reference to Components ReferenceValue
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
    let referenceValue = Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: action
    )
    self.init(value: .referenceValue(referenceValue), type: nil)
  }

  /// Initialize from Asset to Components AssetValue
  private init(asset: FieldValue.Asset) {
    let assetValue = Components.Schemas.AssetValue(
      fileChecksum: asset.fileChecksum,
      size: asset.size,
      referenceChecksum: asset.referenceChecksum,
      wrappingKey: asset.wrappingKey,
      receipt: asset.receipt,
      downloadURL: asset.downloadURL
    )
    self.init(value: .assetValue(assetValue), type: nil)
  }

  /// Initialize from List to Components list value
  private init(list: [FieldValue]) {
    let listValues = list.map { CustomFieldValue.CustomFieldValuePayload($0) }
    self.init(value: .listValue(listValues), type: nil)
  }
}
