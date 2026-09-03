//
//  Components.Schemas.FieldValueRequest.swift
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

/// Extension to convert MistKit FieldValue to OpenAPI FieldValueRequest for API requests
extension Components.Schemas.FieldValueRequest {
  // Initialize from MistKit FieldValue for CloudKit API requests.
  //
  // CloudKit infers a field's type from the value structure, so most values are sent
  // without an explicit `type`. The exceptions are scalars whose JSON form is ambiguous —
  // a `TIMESTAMP`, `BYTES`, or `DOUBLE` is indistinguishable on the wire from an
  // `INT64`/`DOUBLE` number or a `STRING`. For those we tag `type` so CloudKit doesn't
  // infer the wrong type and reject the write with `BAD_REQUEST`. Object/array-shaped
  // values (reference, asset, location, list) are unambiguous and stay untagged.
  //
  // The `switch` is deliberately `default`-free: it is the single dispatch point from the
  // domain enum to the wire representation, so a new `FieldValue` case breaks the build here
  // instead of silently falling into a catch-all.
  // swiftlint:disable:next cyclomatic_complexity
  internal init(from fieldValue: FieldValue) {
    switch fieldValue {
    case .string(let value):
      self.init(value: .StringValue(value))
    case .int64(let value):
      self.init(value: .Int64Value(Int64(value)))
    case .double(let value):
      // Whole-valued doubles serialize without a fraction and would be read as INT64.
      self.init(value: .DoubleValue(value), _type: .DOUBLE)
    case .bytes(let value):
      // A base64 string is otherwise indistinguishable from a STRING.
      self.init(value: .BytesValue(value), _type: .BYTES)
    case .date(let value):
      // Tag TIMESTAMP (else inferred as INT64/DOUBLE) and round to whole milliseconds:
      // CloudKit rejects a fractional TIMESTAMP value (e.g. 1747999812347.89) with
      // BAD_REQUEST "expected type TIMESTAMP", and Date carries sub-millisecond precision.
      self.init(
        value: .DateValue((value.timeIntervalSince1970 * 1_000).rounded()),
        _type: .TIMESTAMP
      )
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
  private init(location: Location) {
    let locationValue = Components.Schemas.LocationValue(
      latitude: location.latitude,
      longitude: location.longitude,
      horizontalAccuracy: location.horizontalAccuracy,
      verticalAccuracy: location.verticalAccuracy,
      altitude: location.altitude,
      speed: location.speed,
      course: location.course,
      // CloudKit rejects a fractional TIMESTAMP on LocationValue.timestamp with BAD_REQUEST,
      // same wire-type constraint as the scalar .date case; Date carries sub-millisecond precision.
      timestamp: location.timestamp.map { ($0.timeIntervalSince1970 * 1_000).rounded() }
    )
    self.init(value: .LocationValue(locationValue))
  }

  /// Initialize from Reference to Components ReferenceValue
  private init(reference: Reference) {
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
    let referenceValue = Components.Schemas.ReferenceValue(
      recordName: reference.recordName,
      action: action
    )
    self.init(value: .ReferenceValue(referenceValue))
  }

  /// Initialize from Asset to Components AssetValue
  private init(asset: Asset) {
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
}
