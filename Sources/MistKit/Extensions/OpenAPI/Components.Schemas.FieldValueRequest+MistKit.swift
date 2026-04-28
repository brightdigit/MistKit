//
//  Components.Schemas.FieldValueRequest+MistKit.swift
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
    if let scalar = Self.makeScalarRequest(from: fieldValue) {
      self = scalar
    } else {
      self = Self.makeComplexRequest(from: fieldValue)
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
    let listValues = list.map { Components.Schemas.ListValuePayload(from: $0) }
    self.init(value: .ListValue(listValues))
  }

  private static func makeScalarRequest(from fieldValue: FieldValue) -> Self? {
    if case .string(let value) = fieldValue {
      return Self(value: .StringValue(value))
    }
    if case .int64(let value) = fieldValue {
      return Self(value: .Int64Value(Int64(value)))
    }
    if case .double(let value) = fieldValue {
      return Self(value: .DoubleValue(value))
    }
    if case .bytes(let value) = fieldValue {
      return Self(value: .BytesValue(value))
    }
    if case .date(let value) = fieldValue {
      return Self(value: .DateValue(value.timeIntervalSince1970 * 1_000))
    }
    return nil
  }

  private static func makeComplexRequest(from fieldValue: FieldValue) -> Self {
    switch fieldValue {
    case .location(let location):
      return Self(location: location)
    case .reference(let reference):
      return Self(reference: reference)
    case .asset(let asset):
      return Self(asset: asset)
    case .list(let list):
      return Self(list: list)
    default:
      return Self(value: .ListValue([]))
    }
  }
}
