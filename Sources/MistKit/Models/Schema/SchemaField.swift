//
//  SchemaField.swift
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

/// A field declaration inside a ``SchemaRecordType``.
public struct SchemaField: Sendable, Hashable {
  /// The field's name, without quotes.
  public let name: String
  /// The field's data type.
  public let type: SchemaFieldType
  /// Whether the field has a `QUERYABLE` index.
  ///
  /// CloudKit rejects query filters on fields without one.
  public let isQueryable: Bool
  /// Whether the field has a `SORTABLE` index.
  ///
  /// CloudKit rejects sorts and range filters on fields without one.
  public let isSortable: Bool
  /// Whether the field has a `SEARCHABLE` (full-text) index.
  public let isSearchable: Bool

  /// Whether this is one of CloudKit's system fields, such as `___recordID`.
  ///
  /// CloudKit reserves identifiers with a leading underscore for the system.
  public var isSystemField: Bool {
    name.hasPrefix("_")
  }

  /// Creates a field.
  public init(
    name: String,
    type: SchemaFieldType,
    isQueryable: Bool = false,
    isSortable: Bool = false,
    isSearchable: Bool = false
  ) {
    self.name = name
    self.type = type
    self.isQueryable = isQueryable
    self.isSortable = isSortable
    self.isSearchable = isSearchable
  }
}
