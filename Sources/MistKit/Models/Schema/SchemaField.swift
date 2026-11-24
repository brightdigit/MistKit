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
///
/// Equality and hashing ignore ``sourceLine``, so a parsed field equals one
/// built in code.
public struct SchemaField: Sendable, Hashable, Codable {
  /// The fields every record type has, whether or not the schema lists them,
  /// in the order CloudKit exports them. None is indexed.
  ///
  /// A schema lists one of them only to give it an index, such as
  /// `"___recordID" REFERENCE QUERYABLE`.
  public static let implicitSystemFields: [Self] = [
    Self(name: "___createTime", type: SchemaFieldType(.timestamp)),
    Self(name: "___createdBy", type: SchemaFieldType(.reference)),
    Self(name: "___etag", type: SchemaFieldType(.string)),
    Self(name: "___modTime", type: SchemaFieldType(.timestamp)),
    Self(name: "___modifiedBy", type: SchemaFieldType(.reference)),
    Self(name: "___recordID", type: SchemaFieldType(.reference)),
  ]

  /// The field's name, without quotes.
  public var name: String
  /// The field's data type.
  public var type: SchemaFieldType
  /// Whether the field has a `QUERYABLE` index.
  ///
  /// CloudKit rejects query filters on fields without one.
  public var isQueryable: Bool
  /// Whether the field has a `SORTABLE` index.
  ///
  /// CloudKit rejects sorts and range filters on fields without one.
  public var isSortable: Bool
  /// Whether the field has a `SEARCHABLE` (full-text) index.
  public var isSearchable: Bool
  /// The 1-based line the declaration starts on, when parsed from text.
  public var sourceLine: Int?

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
    isSearchable: Bool = false,
    sourceLine: Int? = nil
  ) {
    self.name = name
    self.type = type
    self.isQueryable = isQueryable
    self.isSortable = isSortable
    self.isSearchable = isSearchable
    self.sourceLine = sourceLine
  }

  /// Whether two declarations match, ignoring their source lines.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.name == rhs.name && lhs.type == rhs.type && lhs.isQueryable == rhs.isQueryable
      && lhs.isSortable == rhs.isSortable && lhs.isSearchable == rhs.isSearchable
  }

  /// Hashes everything `==` compares.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(type)
    hasher.combine(isQueryable)
    hasher.combine(isSortable)
    hasher.combine(isSearchable)
  }
}
