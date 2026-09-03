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
    if let complexTyped =
      try Self.makeTypedComplex(from: valuePayload, type: typePayload, fieldName: fieldName)
    {
      self = complexTyped
    } else if let simpleValue =
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
    let recordName = RecordName(rawValue: referenceValue.recordName)
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
    self = .asset(Asset(from: assetValue))
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

  /// Build a complex/list `FieldValue` from an explicit CloudKit `type`, validating that the
  /// decoded value's structure satisfies the declared tag (issue #376).
  ///
  /// The `value` `oneOf` is undiscriminated, so — just as a scalar `type` is honored over the
  /// decoded case in ``makeTypedScalar(from:type:fieldName:)`` — a complex/list `type` that
  /// contradicts the value is an internally inconsistent response. Rather than silently
  /// coercing to the value's self-describing structure (a declared `REFERENCE` reading back as
  /// `.int64`), conversion throws ``ConversionError/typeValueMismatch``, matching the fail-loud
  /// treatment of scalar contradictions.
  ///
  /// `ASSETID` maps to the same `AssetValue` as `ASSET` (there is no distinct domain case).
  /// The `LIST` tag is validated only at the container level — the value must be a `ListValue`
  /// — leaving element types to the existing lenient list conversion (the response `type` enum
  /// carries a single `LIST`, unlike the request's granular `*_LIST` family). A `nil` or scalar
  /// `type` returns nil so the caller falls through to scalar typing / inference, leaving
  /// untagged responses on the value-shape path unchanged.
  private static func makeTypedComplex(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    // A nil or scalar `type` is not our concern — defer to scalar typing / inference.
    guard let fieldType, case .complex(let expected) = ResponseTypeTag(fieldType) else {
      return nil
    }
    // The value's decoded shape must satisfy the declared complex/list tag; a contradiction
    // is a fail-loud `typeValueMismatch`. A match reuses the value-shape conversion so a
    // tagged value converts identically to the same value untagged.
    guard expected.matches(value) else {
      try reportComplexMismatch(value, fieldName: fieldName, declaredType: fieldType.rawValue)
    }
    return try makeComplexFieldValue(from: value, fieldName: fieldName)
  }

  /// Throw ``ConversionError/typeValueMismatch`` for a complex/list `type` declared over a
  /// value whose structure can't satisfy it.
  private static func reportComplexMismatch(
    _ value: Components.Schemas.FieldValueResponse.valuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Never {
    let failure = ConversionError.typeValueMismatch(
      fieldName: fieldName,
      declaredType: declaredType,
      value: "\(value)"
    )
    try failure.reportAndThrow()
  }
}
