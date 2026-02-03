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

/// Extension to convert MistKit FieldValue to OpenAPI FieldValueRequest for API requests
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension Components.Schemas.FieldValueRequest {
  /// Initialize from MistKit FieldValue for CloudKit API requests.
  ///
  /// CloudKit infers field types from the value structure, so no type field is sent.
  internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self.init(value: .StringValue(value))
    case .int64(let value):
      self.init(value: .Int64Value(Int64(value)))
    case .double(let value):
      self.init(value: .DoubleValue(value))
    case .bytes(let value):
      self.init(value: .BytesValue(value))
    case .date(let value):
      let milliseconds = value.timeIntervalSince1970 * 1_000
      self.init(value: .DateValue(milliseconds))
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
    self.init(value: .LocationValue(locationValue))
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
    self.init(value: .ReferenceValue(referenceValue))
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
    self.init(value: .AssetValue(assetValue))
  }

  /// Initialize from List to Components list value
  private init(list: [FieldValue]) {
    let listValues = list.map { Self.convertToListValuePayload($0) }
    self.init(value: .ListValue(listValues))
  }

  /// Convert a FieldValue to ListValuePayload (used for list elements)
  internal static func convertToListValuePayload(_ fieldValue: FieldValue) -> Components.Schemas.ListValuePayload {
    switch fieldValue {
    case .string(let value):
      return .StringValue(value)
    case .int64(let value):
      return .Int64Value(Int64(value))
    case .double(let value):
      return .DoubleValue(value)
    case .bytes(let value):
      return .BytesValue(value)
    case .date(let value):
      let milliseconds = value.timeIntervalSince1970 * 1_000
      return .DateValue(milliseconds)
    case .location(let location):
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
      return .LocationValue(locationValue)
    case .reference(let reference):
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
      return .ReferenceValue(referenceValue)
    case .asset(let asset):
      let assetValue = Components.Schemas.AssetValue(
        fileChecksum: asset.fileChecksum,
        size: asset.size,
        referenceChecksum: asset.referenceChecksum,
        wrappingKey: asset.wrappingKey,
        receipt: asset.receipt,
        downloadURL: asset.downloadURL
      )
      return .AssetValue(assetValue)
    case .list(let nestedList):
      // Recursively convert nested lists
      let nestedPayloads = nestedList.map { convertToListValuePayload($0) }
      return .ListValue(nestedPayloads)
    }
  }
}
