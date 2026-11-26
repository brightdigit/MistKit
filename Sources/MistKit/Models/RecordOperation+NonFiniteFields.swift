//
//  RecordOperation+NonFiniteFields.swift
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

extension FieldValue.Arity {
  /// The value, or the list's elements.
  fileprivate var elements: [T] {
    switch self {
    case .value(let value):
      [value]
    case .list(let values):
      values
    }
  }
}

extension Location {
  /// The first number in this location that `JSONEncoder` refuses, as sent.
  fileprivate var firstNonFiniteNumber: Double? {
    let numbers: [Double?] = [
      latitude, longitude, horizontalAccuracy, verticalAccuracy, altitude, speed, course,
      timestamp.map(FieldValue.wireMilliseconds),
    ]
    return numbers.lazy.compactMap { $0 }.first { !$0.isFinite }
  }
}

extension FieldValue {
  /// The first number in this value that `JSONEncoder` refuses (a `NaN` or
  /// infinite `DOUBLE`, location number or timestamp), as sent; `nil` when
  /// there is none.
  internal var firstNonFiniteNumber: Double? {
    switch self {
    case .double(let arity):
      arity.elements.first { !$0.isFinite }
    case .date(let arity):
      arity.elements.lazy.map(Self.wireMilliseconds).first { !$0.isFinite }
    case .location(let arity):
      arity.elements.lazy.compactMap(\.firstNonFiniteNumber).first
    case .string, .int64, .bytes, .reference, .asset:
      nil
    }
  }

  /// A date as the request conversion sends it: whole milliseconds since 1970.
  ///
  /// Matches `Components.Schemas.FieldValueRequest`, so a finite date far
  /// enough out to overflow to infinity in milliseconds is caught too.
  fileprivate static func wireMilliseconds(_ date: Date) -> Double {
    (date.timeIntervalSince1970 * 1_000).rounded()
  }
}

extension RecordOperation {
  /// The error encoding this operation would throw for a `NaN` or infinite
  /// number, found without encoding it.
  ///
  /// This is ``CloudKitError/invalidFieldValue(recordName:fieldName:underlying:)``
  /// naming the record and field, the error
  /// ``CloudKitService/modifyRecords(_:atomic:zoneID:desiredKeys:numbersAsStrings:database:)``
  /// throws when `JSONEncoder` refuses the same value; `nil` when every
  /// number is finite.
  internal func nonFiniteFieldError() -> CloudKitError? {
    for fieldName in fields.keys.sorted() {
      guard let number = fields[fieldName]?.firstNonFiniteNumber else {
        continue
      }
      let context = EncodingError.Context(
        codingPath: [WireFieldKey(stringValue: "fields"), WireFieldKey(stringValue: fieldName)],
        debugDescription: "Unable to encode Double.\(number) directly in JSON."
      )
      return .invalidFieldValue(
        recordName: recordName,
        fieldName: fieldName,
        underlying: .invalidValue(number, context)
      )
    }
    return nil
  }
}
