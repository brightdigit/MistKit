//
//  FieldType.swift
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

/// A field's type as its values carry it: one CloudKit primitive, or a list of
/// one.
///
/// ``SchemaFieldType`` keeps what a schema says (`ENCRYPTED`,
/// `NUMBER PREFERRED AS`); this is what's left once that is resolved, and what
/// a ``FieldValue`` reports as its ``FieldValue/fieldType``. CloudKit has no
/// lists of lists, and MistKit never produces `.list(.list(…))`.
public indirect enum FieldType: Sendable, Hashable, Codable {
  /// `STRING`
  case string
  /// `INT64`
  case int64
  /// `DOUBLE`
  case double
  /// `TIMESTAMP`, a ``FieldValue/date(_:)-enum.case`` value.
  case timestamp
  /// `BYTES`
  case bytes
  /// `REFERENCE`
  case reference
  /// `ASSET`
  case asset
  /// `LOCATION`
  case location
  /// `LIST<element>`
  case list(FieldType)

  /// Whether this is a `LIST<…>` type.
  public var isList: Bool {
    if case .list = self {
      return true
    }
    return false
  }

  /// A list's element type, or the type itself when it isn't a list.
  public var elementType: FieldType {
    if case .list(let element) = self {
      return element
    }
    return self
  }
}
