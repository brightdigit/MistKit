//
//  FieldValue+Components.swift
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

/// Extension to convert OpenAPI Components.Schemas.FieldValueResponse to MistKit FieldValue
extension FieldValue {
  /// Initialize from OpenAPI Components.Schemas.FieldValueResponse (from API responses).
  ///
  /// - Parameters:
  ///   - fieldData: The decoded CloudKit field value to convert.
  ///   - fieldName: The name of the field being converted, used to give
  ///     conversion-failure diagnostics meaningful context.
  /// - Throws: ``ConversionError`` if the value can't be mapped to a `FieldValue`.
  internal init(
    _ fieldData: Components.Schemas.FieldValueResponse,
    fieldName: String
  ) throws(ConversionError) {
    try self.init(valuePayload: fieldData.value, typePayload: fieldData._type, fieldName: fieldName)
  }

  /// Initialize from field value and type
  private init(
    valuePayload: Components.Schemas.FieldValueResponse.valuePayload,
    typePayload: Components.Schemas.FieldValueResponse._typePayload?,
    fieldName: String
  ) throws(ConversionError) {
    if let simpleValue =
      try Self.makeSimpleFieldValue(from: valuePayload, type: typePayload, fieldName: fieldName)
    {
      self = simpleValue
    } else if let complexValue =
      try Self.makeComplexFieldValue(from: valuePayload, fieldName: fieldName)
    {
      self = complexValue
    } else {
      let failure = ConversionError.unmappableFieldValue(
        fieldName: fieldName,
        value: "\(valuePayload)",
        type: typePayload.map { "\($0)" }
      )
      try failure.reportAndThrow()
    }
  }

  /// Initialize from location field value
  internal init(
    locationValue: Components.Schemas.LocationValue
  ) {
    let location = Location(
      latitude: locationValue.latitude,
      longitude: locationValue.longitude,
      horizontalAccuracy: locationValue.horizontalAccuracy,
      verticalAccuracy: locationValue.verticalAccuracy,
      altitude: locationValue.altitude,
      speed: locationValue.speed,
      course: locationValue.course,
      timestamp: locationValue.timestamp.map { Date(timeIntervalSince1970: $0 / 1_000) }
    )
    self = .location(location)
  }

  /// Initialize from reference field value
  internal init(
    referenceValue: Components.Schemas.ReferenceValue
  ) {
    let recordName = referenceValue.recordName
    let action: Reference.Action?
    switch referenceValue.action {
    case .DELETE_SELF:
      action = .deleteSelf
    case .NONE:
      action = Reference.Action.none
    case nil:
      action = nil
    }
    let reference = Reference(
      recordName: recordName,
      action: action
    )
    self = .reference(reference)
  }

  /// Initialize from asset field value
  internal init(assetValue: Components.Schemas.AssetValue) {
    let asset = Asset(
      fileChecksum: assetValue.fileChecksum,
      size: assetValue.size,
      referenceChecksum: assetValue.referenceChecksum,
      wrappingKey: assetValue.wrappingKey,
      receipt: assetValue.receipt,
      downloadURL: assetValue.downloadURL
    )
    self = .asset(asset)
  }

  private static func makeComplexFieldValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    if case .LocationValue(let locationValue) = value {
      return Self(locationValue: locationValue)
    }
    if case .ReferenceValue(let referenceValue) = value {
      return Self(referenceValue: referenceValue)
    }
    if case .AssetValue(let assetValue) = value {
      return Self(assetValue: assetValue)
    }
    if case .ListValue(let listValue) = value {
      return try Self(listValue: listValue, fieldName: fieldName)
    }
    return nil
  }
}
