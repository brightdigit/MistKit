//
//  FieldValue+Codable.swift
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

// MARK: - Codable

extension FieldValue {
  /// Decodes a CloudKit field dictionary that carries its type,
  /// `{"value": …, "type": …}`.
  ///
  /// This is the shape ``WireFieldValue`` writes with
  /// ``FieldTypeTagging/always`` and the shape ``encode(to:)`` writes, so
  /// every value reads back as the kind it was written: a `TIMESTAMP` as
  /// `.date`, a `BYTES` as `.bytes`, a whole-valued `DOUBLE` as `.double`,
  /// and an empty list with its element type.
  ///
  /// - Throws: `DecodingError.dataCorrupted` when the dictionary has no
  ///   `type`, or its `value` is `null` (a cleared field isn't a
  ///   `FieldValue`); otherwise the same errors as ``WireFieldValue``'s
  ///   decoding.
  public init(from decoder: any Decoder) throws {
    let wire = try WireFieldValue(from: decoder)
    guard let value = wire.value else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "A FieldValue can't be null."
        )
      )
    }
    guard wire.typeTagging == .always else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "A FieldValue needs a type: {\"value\": …, \"type\": …}."
        )
      )
    }
    self = value
  }

  /// Encodes the value as a CloudKit field dictionary with its type,
  /// `{"value": …, "type": …}` (see ``WireFieldValue`` with
  /// ``FieldTypeTagging/always``).
  ///
  /// - Throws: `EncodingError` when a number isn't finite.
  public func encode(to encoder: any Encoder) throws {
    try WireFieldValue(self, typeTagging: .always).encode(to: encoder)
  }
}

// MARK: - Helper Methods

extension FieldValue {
  /// Create an int64 FieldValue from a Bool
  ///
  /// CloudKit represents booleans as INT64 (0/1) on the wire.
  /// Creates a FieldValue from a Swift Bool value.
  ///
  /// This initializer converts Swift Bool to the appropriate int64 representation
  /// used by CloudKit (1 for true, 0 for false).
  ///
  /// - Parameter booleanValue: The boolean value to convert
  public init(booleanValue: Bool) {
    self = .int64(.value(booleanValue ? 1 : 0))
  }
}
