//
//  CodingUserInfoKey+WireFormat.swift
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

extension CodingUserInfoKey {
  /// Field types for decoding untyped CloudKit field dictionaries, as
  /// `[String: SchemaFieldType]` keyed by field name.
  ///
  /// A field dictionary's own `type` always wins. Without one, a
  /// ``WireFieldValue`` (and so a ``WireRecord``, ``WireRecordOperation`` or
  /// ``WireRecordDocument``) decodes its value as the type given here, then
  /// falls back to the value's JSON shape. Give types to read pasted or
  /// hand-written JSON whose values are ambiguous: an untyped `[]`, a base64
  /// `BYTES` string or a millisecond `TIMESTAMP`.
  ///
  /// ```swift
  /// let decoder = JSONDecoder()
  /// decoder.userInfo[.cloudKitFieldTypes] = ["seenAt": SchemaFieldType(.timestamp)]
  /// let record = try decoder.decode(WireRecord.self, from: data)
  /// ```
  public static let cloudKitFieldTypes: CodingUserInfoKey = {
    guard let key = CodingUserInfoKey(rawValue: "MistKit.cloudKitFieldTypes") else {
      preconditionFailure("CodingUserInfoKey accepts any raw value")
    }
    return key
  }()
}

extension Decoder {
  /// The field types in ``CodingUserInfoKey/cloudKitFieldTypes``; none when unset.
  internal var cloudKitFieldTypes: [String: SchemaFieldType] {
    userInfo[.cloudKitFieldTypes] as? [String: SchemaFieldType] ?? [:]
  }
}
