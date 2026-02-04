//
//  Components+ListValuePayload.swift
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

extension Components.Schemas.ListValuePayload {
  /// Initialize from MistKit FieldValue for list elements
  internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self = .StringValue(value)
    case .int64(let value):
      self = .Int64Value(Int64(value))
    case .double(let value):
      self = .DoubleValue(value)
    case .bytes(let value):
      self = .BytesValue(value)
    case .date(let value):
      let milliseconds = value.timeIntervalSince1970 * 1_000
      self = .DateValue(milliseconds)
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
      self = .LocationValue(locationValue)
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
      self = .ReferenceValue(referenceValue)
    case .asset(let asset):
      let assetValue = Components.Schemas.AssetValue(
        fileChecksum: asset.fileChecksum,
        size: asset.size,
        referenceChecksum: asset.referenceChecksum,
        wrappingKey: asset.wrappingKey,
        receipt: asset.receipt,
        downloadURL: asset.downloadURL
      )
      self = .AssetValue(assetValue)
    case .list(let nestedList):
      // Recursively convert nested lists
      let nestedPayloads = nestedList.map { Self(from: $0) }
      self = .ListValue(nestedPayloads)
    }
  }
}
