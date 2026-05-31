//
//  FieldValue+Components+Scalar.swift
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

/// Scalar-value conversions for `FieldValue` ← `Components.Schemas` response types.
extension FieldValue {
  internal static func makeSimpleFieldValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    // The `value` oneOf is undiscriminated and decoded first-match-wins
    // (String → Int64 → Double → Bytes → Date), so a whole-millisecond TIMESTAMP
    // arrives as Int64Value and a BYTES base64 string arrives as StringValue.
    // When CloudKit supplies an explicit scalar `type`, honor it over the decoded case
    // so these ambiguous scalars round-trip correctly; otherwise infer from the case.
    if let typed = try makeTypedScalar(from: value, type: fieldType, fieldName: fieldName) {
      return typed
    }
    return makeInferredScalar(from: value)
  }

  /// Build a scalar `FieldValue` from an explicit CloudKit `type`, recovering the value
  /// from whichever undiscriminated `oneOf` case it happened to decode into.
  ///
  /// All five scalar types are validated against the value's category (numeric vs. string).
  /// A declared scalar type whose value can't satisfy it (e.g. `TIMESTAMP` over a string)
  /// is an internally inconsistent response and throws ``ConversionError/typeValueMismatch``
  /// rather than silently coercing to the value's shape. Only the genuinely ambiguous
  /// scalars (`TIMESTAMP`/`DOUBLE`/`BYTES`) produce a value here; `INT64`/`STRING` validate
  /// the category then return nil to defer to inference — which already yields the right
  /// case and, for `INT64`, avoids truncating a fractional number. A `nil` or complex/list
  /// `type` returns nil and is handled by inference or `makeComplexFieldValue`.
  private static func makeTypedScalar(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    guard let fieldType else {
      return nil
    }
    switch fieldType {
    case .TIMESTAMP, .DOUBLE, .INT64:
      return try makeTypedNumericScalar(from: value, type: fieldType, fieldName: fieldName)
    case .BYTES, .STRING:
      return try makeTypedStringScalar(from: value, type: fieldType, fieldName: fieldName)
    default:
      return nil
    }
  }

  /// Numeric branch of ``makeTypedScalar(from:type:fieldName:)`` — validates the value
  /// is numeric, then returns a domain value for `TIMESTAMP`/`DOUBLE` or nil for `INT64`
  /// (which defers to inference to avoid truncating a fractional number).
  private static func makeTypedNumericScalar(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    let number = try requireNumeric(
      value, fieldName: fieldName, declaredType: fieldType.rawValue
    )
    switch fieldType {
    case .TIMESTAMP:
      return .date(Date(timeIntervalSince1970: number / 1_000))
    case .DOUBLE:
      return .double(number)
    default:
      return nil
    }
  }

  /// String branch of ``makeTypedScalar(from:type:fieldName:)`` — validates the value
  /// is a string, then returns a `.bytes` domain value for `BYTES` or nil for `STRING`
  /// (which defers to inference, already producing `.string`).
  private static func makeTypedStringScalar(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    let string = try requireString(
      value, fieldName: fieldName, declaredType: fieldType.rawValue
    )
    if case .BYTES = fieldType {
      return .bytes(string)
    }
    return nil
  }

  /// Require that `value` carries a number, throwing ``ConversionError/typeValueMismatch``
  /// when a numeric `type` is declared over a non-numeric value.
  private static func requireNumeric(
    _ value: Components.Schemas.FieldValueResponse.valuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Double {
    guard let number = numericValue(from: value) else {
      let failure = ConversionError.typeValueMismatch(
        fieldName: fieldName,
        declaredType: declaredType,
        value: "\(value)"
      )
      try failure.reportAndThrow()
    }
    return number
  }

  /// Require that `value` carries a string, throwing ``ConversionError/typeValueMismatch``
  /// when a string `type` is declared over a non-string value.
  private static func requireString(
    _ value: Components.Schemas.FieldValueResponse.valuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> String {
    guard let string = stringValue(from: value) else {
      let failure = ConversionError.typeValueMismatch(
        fieldName: fieldName,
        declaredType: declaredType,
        value: "\(value)"
      )
      try failure.reportAndThrow()
    }
    return string
  }

  /// Infer a scalar `FieldValue` from the decoded `oneOf` case when no usable `type`
  /// is present. Lossy for ambiguous scalars: a base64 BYTES reads back as `.string`,
  /// and a whole-number TIMESTAMP reads back as `.int64`.
  private static func makeInferredScalar(
    from value: Components.Schemas.FieldValueResponse.valuePayload
  ) -> FieldValue? {
    if case .StringValue(let strVal) = value {
      return .string(strVal)
    }
    if case .Int64Value(let intVal) = value {
      return .int64(Int(intVal))
    }
    if case .DoubleValue(let dblVal) = value {
      return .double(dblVal)
    }
    if case .BytesValue(let bytesVal) = value {
      return .bytes(bytesVal)
    }
    if case .DateValue(let dateVal) = value {
      return .date(Date(timeIntervalSince1970: dateVal / 1_000))
    }
    return nil
  }

  /// Extract a `Double` from any numeric `oneOf` case (Int64/Double/Date all arrive as numbers).
  private static func numericValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload
  ) -> Double? {
    if case .Int64Value(let intVal) = value {
      return Double(intVal)
    }
    if case .DoubleValue(let dblVal) = value {
      return dblVal
    }
    if case .DateValue(let dateVal) = value {
      return dateVal
    }
    return nil
  }

  /// Extract a `String` from any string-backed `oneOf` case (String/Bytes both arrive as strings).
  private static func stringValue(
    from value: Components.Schemas.FieldValueResponse.valuePayload
  ) -> String? {
    if case .StringValue(let strVal) = value {
      return strVal
    }
    if case .BytesValue(let bytesVal) = value {
      return bytesVal
    }
    return nil
  }
}
