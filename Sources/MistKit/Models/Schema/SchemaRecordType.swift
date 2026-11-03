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
public struct SchemaRecordType: Sendable, Hashable {
  /// The record type's name.
  public let name: String
  /// The fields the schema declares, in source order.
  ///
  /// CloudKit adds the system fields (`___recordID`, `___createTime`, …)
  /// implicitly. They appear here only when the schema mentions them,
  /// usually to give them an index.
  public let fields: [SchemaField]
  /// The `GRANT` clauses, in source order.
  public let grants: [SchemaGrant]

  /// Creates a record type.
  public init(name: String, fields: [SchemaField] = [], grants: [SchemaGrant] = []) {
    self.name = name
    self.fields = fields
    self.grants = grants
  }

  /// The field with this exact name, if the schema declares one.
  public func field(named name: String) -> SchemaField? {
    fields.first { $0.name == name }
  }
}
