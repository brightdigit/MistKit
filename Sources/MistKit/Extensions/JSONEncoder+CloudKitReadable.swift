//
//  JSONEncoder+CloudKitReadable.swift
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

public import Foundation

extension JSONEncoder {
  /// A new encoder for CloudKit Web Services JSON that people read: pretty
  /// printed, keys sorted, slashes unescaped.
  ///
  /// Sorted keys keep the output byte for byte the same on every platform,
  /// whatever order a type writes its keys in. Pair it with
  /// ``FieldTypeTagging/always`` so every field carries its `type` and a `5`
  /// stays a `DOUBLE`.
  ///
  /// ```swift
  /// let data = try JSONEncoder.cloudKitReadable.encode(records.map { WireRecord($0) })
  /// ```
  ///
  /// The wire types write one fixed form: TIMESTAMP as whole milliseconds,
  /// BYTES as base64, numbers as JSON numbers. If that ever needs options
  /// (type tags on or off, ISO 8601 instead of milliseconds, a request's
  /// `numbersAsStrings`), `userInfo` is where they go, read by the wire types'
  /// `encode(to:)`, as ``CodingUserInfoKey/cloudKitFieldTypes`` is on decoding.
  public static var cloudKitReadable: JSONEncoder {
    let encoder = JSONEncoder()
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
    return encoder
  }
}
