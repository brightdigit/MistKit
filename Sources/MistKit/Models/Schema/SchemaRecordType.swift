//
//  SchemaRecordType.swift
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

/// A `RECORD TYPE` declaration in a CloudKit schema.
///
/// Equality and hashing ignore ``sourceLine``, so a parsed record type equals
/// one built in code.
public struct SchemaRecordType: Sendable, Hashable, Codable {
  /// The record type's name.
  public var name: String
  /// The fields the schema declares, in source order.
  ///
  /// CloudKit adds the system fields (`___recordID`, `___createTime`, …)
  /// implicitly. They appear here only when the schema mentions them,
  /// usually to give them an index; ``fieldsIncludingImplicit`` adds the rest.
  public var fields: [SchemaField]
  /// The `GRANT` clauses, in source order.
  public var grants: [SchemaGrant]
  /// The 1-based line of `RECORD TYPE name`, when parsed from text.
  public var sourceLine: Int?

  /// Every field a record of this type has: the implicit system fields the
  /// schema doesn't list (unindexed, in CloudKit's order), then ``fields``.
  public var fieldsIncludingImplicit: [SchemaField] {
    SchemaField.implicitSystemFields.filter { field(named: $0.name) == nil } + fields
  }

  /// Creates a record type.
  public init(
    name: String,
    fields: [SchemaField] = [],
    grants: [SchemaGrant] = [],
    sourceLine: Int? = nil
  ) {
    self.name = name
    self.fields = fields
    self.grants = grants
    self.sourceLine = sourceLine
  }

  /// Whether two declarations match, ignoring their source lines.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.name == rhs.name && lhs.fields == rhs.fields && lhs.grants == rhs.grants
  }

  /// Hashes everything ``==`` compares.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(name)
    hasher.combine(fields)
    hasher.combine(grants)
  }

  /// The field with this exact name, if the schema declares one.
  public func field(named name: String) -> SchemaField? {
    fields.first { $0.name == name }
  }
}
