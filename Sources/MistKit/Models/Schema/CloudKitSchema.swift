//
//  CloudKitSchema.swift
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

/// A container environment's schema, parsed from CloudKit Schema Language.
///
/// CloudKit's Management API returns schemas as text in the CloudKit Schema
/// Language (the `.ckdb` format `cktool export-schema` writes). Parse that text
/// with ``init(parsing:)`` to get each record type's fields, their data types,
/// and the `QUERYABLE` / `SORTABLE` / `SEARCHABLE` index options CloudKit
/// enforces on queries.
///
/// CloudKit doesn't preserve comments and may reorder elements when it returns
/// a schema, so two exports of the same schema can differ textually.
public struct CloudKitSchema: Sendable, Hashable {
  /// Custom security roles declared with `CREATE ROLE`, in source order.
  ///
  /// The implicit roles (`_creator`, `_icloud`, `_world`) are not listed
  /// unless the schema declares them.
  public let roles: [String]
  /// Record types, in source order.
  public let recordTypes: [SchemaRecordType]

  /// Creates a schema from already-parsed parts.
  public init(roles: [String] = [], recordTypes: [SchemaRecordType] = []) {
    self.roles = roles
    self.recordTypes = recordTypes
  }

  /// Parses CloudKit Schema Language text.
  ///
  /// - Parameter text: A complete schema starting with `DEFINE SCHEMA`.
  /// - Throws: ``SchemaParseError`` naming the line and column of the first
  ///   problem.
  public init(parsing text: String) throws {
    var parser = SchemaParser(text: text)
    self = try parser.parseSchema()
  }

  /// The record type with this exact name, if the schema declares one.
  public func recordType(named name: String) -> SchemaRecordType? {
    recordTypes.first { $0.name == name }
  }
}
