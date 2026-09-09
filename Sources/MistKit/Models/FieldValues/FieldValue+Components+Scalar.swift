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
  /// A decoded response `value` narrowed to its five scalar `oneOf` cases.
  ///
  /// This is the one place the nine `valuePayload` cases are enumerated for scalar work:
  /// `requireNumeric`, `requireString`, and `makeInferredScalar` project off it instead of
  /// each walking the payload themselves. Every switch over it — here and in ``init(_:)`` —
  /// is `default`-free, so a new `oneOf` case breaks the build rather than silently reading
  /// as "not a scalar", and a new scalar case has to be classified for all three projections.
  private enum ScalarPayload {
    case string(String)
    case bytes(String)
    case int64(Int64)
    case double(Double)
    /// Milliseconds since the epoch, as CloudKit sends a `TIMESTAMP`.
    case date(Double)

    /// The `FieldValue` first-match-wins inference produces for this payload. Lossy for the
    /// ambiguous scalars: a base64 BYTES reads back as `.string`, and a whole-number
    /// TIMESTAMP reads back as `.int64`. `BytesValue` stays a wire `String`; decode to
    /// `Data` here, falling back to `.string` if the payload is not valid base64.
    fileprivate var inferred: FieldValue {
      switch self {
      case .string(let strVal):
        return .string(strVal)
      case .bytes(let bytesVal):
        if let data = Data(base64Encoded: bytesVal) {
          return .bytes(data)
        }
        return .string(bytesVal)
      case .int64(let intVal):
        return .int64(Int(intVal))
      case .double(let dblVal):
        return .double(dblVal)
      case .date(let dateVal):
        return .date(Date(timeIntervalSince1970: dateVal / 1_000))
      }
    }

    /// The numeric payload, or `nil` when the value is string-backed. `Int64Value`,
    /// `DoubleValue`, and `DateValue` all arrive as JSON numbers.
    fileprivate var number: Double? {
      switch self {
      case .int64(let intVal):
        return Double(intVal)
      case .double(let dblVal):
        return dblVal
      case .date(let dateVal):
        return dateVal
      case .string, .bytes:
        return nil
      }
    }

    /// The string payload, or `nil` when the value is numeric. `StringValue` and
    /// `BytesValue` both arrive as JSON strings.
    fileprivate var text: String? {
      switch self {
      case .string(let strVal):
        return strVal
      case .bytes(let strVal):
        return strVal
      case .int64, .double, .date:
        return nil
      }
    }

    /// Narrow a decoded response `value` to a scalar, returning `nil` for the structured
    /// cases (which are handled by `makeComplexFieldValue`).
    fileprivate init?(_ value: Components.Schemas.FieldValueResponse.valuePayload) {
      switch value {
      case .StringValue(let strVal):
        self = .string(strVal)
      case .BytesValue(let bytesVal):
        self = .bytes(bytesVal)
      case .Int64Value(let intVal):
        self = .int64(intVal)
      case .DoubleValue(let dblVal):
        self = .double(dblVal)
      case .DateValue(let dateVal):
        self = .date(dateVal)
      case .LocationValue, .ReferenceValue, .AssetValue, .ListValue:
        return nil
      }
    }
  }

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

  // Build a scalar `FieldValue` from an explicit CloudKit `type`, recovering the value
  // from whichever undiscriminated `oneOf` case it happened to decode into.
  //
  // All five scalar types are validated against the value's category (numeric vs. string)
  // by ``FieldValue/ResponseTypeTag``. A declared scalar type whose value can't satisfy it
  // (e.g. `TIMESTAMP` over a string) is an internally inconsistent response and throws
  // ``ConversionError/typeValueMismatch`` rather than silently coercing to the value's
  // shape. Only the genuinely ambiguous scalars (`TIMESTAMP`/`DOUBLE`/`BYTES`) produce a
  // value here; `INT64`/`STRING` validate the category then return nil to defer to
  // inference — which already yields the right case and, for `INT64`, avoids truncating a
  // fractional number. A `nil` or complex/list `type` returns nil and is handled by
  // inference or `makeComplexFieldValue`.
  // swiftlint:disable:next cyclomatic_complexity
  private static func makeTypedScalar(
    from value: Components.Schemas.FieldValueResponse.valuePayload,
    type fieldType: Components.Schemas.FieldValueResponse._typePayload?,
    fieldName: String
  ) throws(ConversionError) -> FieldValue? {
    guard let fieldType else {
      return nil
    }
    let declared = fieldType.rawValue
    switch ResponseTypeTag(fieldType) {
    case .numeric(.timestamp):
      let number = try requireNumeric(value, fieldName: fieldName, declaredType: declared)
      return .date(Date(timeIntervalSince1970: number / 1_000))
    case .numeric(.double):
      return .double(try requireNumeric(value, fieldName: fieldName, declaredType: declared))
    case .numeric(.int64):
      // Validate the category, then defer to inference so a fractional number isn't truncated.
      _ = try requireNumeric(value, fieldName: fieldName, declaredType: declared)
      return nil
    case .text(.bytes):
      let string = try requireString(value, fieldName: fieldName, declaredType: declared)
      return .bytes(try dataFromBase64(string, fieldName: fieldName, declaredType: declared))
    case .text(.string):
      // Validate the category, then defer to inference, which already produces `.string`.
      _ = try requireString(value, fieldName: fieldName, declaredType: declared)
      return nil
    case .complex:
      return nil
    }
  }

  /// Require that `value` carries a number, throwing ``ConversionError/typeValueMismatch``
  /// when a numeric `type` is declared over a non-numeric value.
  private static func requireNumeric(
    _ value: Components.Schemas.FieldValueResponse.valuePayload,
    fieldName: String,
    declaredType: String
  ) throws(ConversionError) -> Double {
    guard let number = ScalarPayload(value)?.number else {
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
    guard let string = ScalarPayload(value)?.text else {
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
    ScalarPayload(value)?.inferred
  }
}
