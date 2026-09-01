//
//  Components.Schemas.ListValuePayload.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation
internal import MistKitOpenAPI

extension Components.Schemas.ListValuePayload {
  /// Initialize from MistKit FieldValue for list elements
  ///
  /// The `switch` is deliberately `default`-free: it is the single dispatch point from the
  /// domain enum to a list element's wire representation, so a new `FieldValue` case breaks
  /// the build here instead of silently degrading. (It previously fell through to a
  /// `default: assertionFailure(...)` that returned an empty list — a debug-only trap that
  /// in release builds would have written `[]` in place of the value.)
  internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self = .StringValue(value)
    case .int64(let value):
      self = .Int64Value(Int64(value))
    case .double(let value):
      self = .DoubleValue(value)
    case .bytes(let value):
      self = .BytesValue(value.base64EncodedString())
    case .date(let value):
      // Round to whole milliseconds, same constraint as the scalar `.date` case in
      // `Components.Schemas.FieldValueRequest`: CloudKit rejects a fractional TIMESTAMP
      // with BAD_REQUEST "expected type TIMESTAMP", and Date carries sub-millisecond
      // precision. List elements carry no `type` tag of their own, so the value's shape
      // is all CloudKit has to go on.
      self = .DateValue((value.timeIntervalSince1970 * 1_000).rounded())
    case .location(let location):
      self = .LocationValue(Self.makeLocationValue(location))
    case .reference(let reference):
      self = .ReferenceValue(Self.makeReferenceValue(reference))
    case .asset(let asset):
      self = .AssetValue(Self.makeAssetValue(asset))
    case .list(let nestedList):
      self = .ListValue(nestedList.map { Self(from: $0) })
    }
  }

  private static func makeLocationValue(_ location: Location)
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
      // Rounded for the same reason as the `.date` element above.
      timestamp: location.timestamp.map { ($0.timeIntervalSince1970 * 1_000).rounded() }
    )
  }

  private static func makeReferenceValue(_ reference: Reference)
    -> Components.Schemas.ReferenceValue
  {
    let action: Components.Schemas.ReferenceValue.actionPayload?
    switch reference.action {
    case .some(.deleteSelf):
      action = .DELETE_SELF
    case .some(.none):
      action = .NONE
    case .some(.validate):
      action = .VALIDATE
    case nil:
      action = nil
    }
    return Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: action
    )
  }

  private static func makeAssetValue(_ asset: Asset) -> Components.Schemas.AssetValue {
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
