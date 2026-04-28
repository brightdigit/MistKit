//
//  Components.Schemas.ListValuePayload+MistKit.swift
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

extension Components.Schemas.ListValuePayload {
  /// Initialize from MistKit FieldValue for list elements
  internal init(from fieldValue: FieldValue) {
    if let payload = Self.makeScalarPayload(from: fieldValue) {
      self = payload
    } else {
      self = Self.makeComplexPayload(from: fieldValue)
    }
  }

  private static func makeScalarPayload(from fieldValue: FieldValue) -> Self? {
    if case .string(let value) = fieldValue {
      return .StringValue(value)
    }
    if case .int64(let value) = fieldValue {
      return .Int64Value(Int64(value))
    }
    if case .double(let value) = fieldValue {
      return .DoubleValue(value)
    }
    if case .bytes(let value) = fieldValue {
      return .BytesValue(value)
    }
    if case .date(let value) = fieldValue {
      return .DateValue(value.timeIntervalSince1970 * 1_000)
    }
    return nil
  }

  private static func makeComplexPayload(from fieldValue: FieldValue) -> Self {
    switch fieldValue {
    case .location(let location):
      return .LocationValue(makeLocationValue(location))
    case .reference(let reference):
      return .ReferenceValue(makeReferenceValue(reference))
    case .asset(let asset):
      return .AssetValue(makeAssetValue(asset))
    case .list(let nestedList):
      return .ListValue(nestedList.map { Self(from: $0) })
    default:
      return .ListValue([])
    }
  }

  private static func makeLocationValue(_ location: FieldValue.Location)
    -> Components.Schemas.LocationValue
  {
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
  }

  private static func makeReferenceValue(_ reference: FieldValue.Reference)
    -> Components.Schemas.ReferenceValue
  {
    let action: Components.Schemas.ReferenceValue.actionPayload?
    switch reference.action {
    case .some(.deleteSelf):
      action = .DELETE_SELF
    case .some(.none):
      action = .NONE
    case nil:
      action = nil
    }
    return Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: action
    )
  }

  private static func makeAssetValue(_ asset: FieldValue.Asset) -> Components.Schemas.AssetValue {
    Components.Schemas.AssetValue(
      fileChecksum: asset.fileChecksum,
      size: asset.size,
      referenceChecksum: asset.referenceChecksum,
      wrappingKey: asset.wrappingKey,
      receipt: asset.receipt,
      downloadURL: asset.downloadURL
    )
  }
}
