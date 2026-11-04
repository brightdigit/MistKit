//
//  SchemaParser.swift
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

/// A recursive-descent parser for CloudKit Schema Language.
///
/// Follows the grammar in Apple's "Integrating a Text-Based Schema into Your
/// Workflow": `DEFINE SCHEMA` followed by `CREATE ROLE` and `RECORD TYPE`
/// statements, each ending in `;`. Keywords are case-insensitive.
///
/// Strictness: bare names can't start with `_` or be one of
/// ``reservedWords``; a trailing comma before `)` and a missing `;` after the
/// last declaration are tolerated; a role, record type or field defined twice
/// is an error, as is `ENCRYPTED` on a type that can't be encrypted.
internal struct SchemaParser {
  /// Words that must be quoted to be used as names.
  internal static let reservedWords: Set<String> = [
    "GRANT", "PREFERRED", "QUERYABLE", "SORTABLE", "SEARCHABLE",
  ]

  private let text: String
  internal private(set) var tokens: [SchemaToken] = []
  internal var position = 0

  internal var current: SchemaToken {
    tokens[position]
  }

  internal init(text: String) {
    self.text = text
  }

  internal mutating func parseSchema() throws -> CloudKitSchema {
    var tokenizer = SchemaTokenizer(text: text)
    tokens = try tokenizer.tokenize()
    position = 0

    try expectKeyword("DEFINE")
    try expectKeyword("SCHEMA")

    var schema = CloudKitSchema()
    while current.kind != .end {
      try declaration(into: &schema)
      // Apple's grammar ends every declaration with ";". Allow it to be left
      // off the last one, since nothing can be misread there.
      guard consumeSymbol(";") || current.kind == .end else {
        throw unexpected(expecting: "\";\"")
      }
    }
    return schema
  }

  // MARK: - Statements

  private mutating func declaration(into schema: inout CloudKitSchema) throws {
    if consumeKeyword("CREATE") {
      try expectKeyword("ROLE")
      let role = try identifier(describing: "a role name")
      guard !schema.roles.contains(role.name) else {
        throw SchemaParseError(
          at: role.token,
          message: "role \"\(role.name)\" is already defined"
        )
      }
      schema.roles.append(role.name)
    } else if current.isKeyword("RECORD") {
      let line = current.line
      advance()
      try expectKeyword("TYPE")
      let name = try identifier(describing: "a record type name")
      guard schema.recordType(named: name.name) == nil else {
        throw SchemaParseError(
          at: name.token,
          message: "record type \"\(name.name)\" is already defined"
        )
      }
      schema.recordTypes.append(try recordTypeBody(named: name.name, line: line))
    } else {
      throw unexpected(expecting: "CREATE ROLE or RECORD TYPE")
    }
  }

  private mutating func recordTypeBody(named name: String, line: Int) throws
    -> SchemaRecordType
  {
    var recordType = SchemaRecordType(name: name, sourceLine: line)
    try expectSymbol("(")
    if consumeSymbol(")") {
      return recordType
    }
    while true {
      try element(into: &recordType)
      // A trailing comma before ")" is tolerated.
      guard consumeSymbol(",") else {
        guard consumeSymbol(")") else {
          throw unexpected(expecting: "\",\" or \")\"")
        }
        return recordType
      }
      if consumeSymbol(")") {
        return recordType
      }
    }
  }

  private mutating func element(into recordType: inout SchemaRecordType) throws {
    if consumeKeyword("GRANT") {
      recordType.grants.append(try grant())
      return
    }
    let name = try identifier(describing: "a field name or GRANT")
    guard recordType.field(named: name.name) == nil else {
      throw SchemaParseError(
        at: name.token,
        message: "field \"\(name.name)\" is already defined in \(recordType.name)"
      )
    }
    var field = SchemaField(name: name.name, type: try dataType(), sourceLine: name.token.line)
    try indexes(into: &field)
    recordType.fields.append(field)
  }

  /// `QUERYABLE`, `SEARCHABLE` and `SORTABLE`, in any order.
  private mutating func indexes(into field: inout SchemaField) throws {
    while let keyword = current.keyword {
      switch keyword {
      case "QUERYABLE": field.isQueryable = true
      case "SORTABLE": field.isSortable = true
      case "SEARCHABLE": field.isSearchable = true
      default:
        throw SchemaParseError(at: current, message: "unknown field option \"\(keyword)\"")
      }
      advance()
    }
  }

  /// `READ, WRITE TO role`, after `GRANT`.
  private mutating func grant() throws -> SchemaGrant {
    var permissions = [try permission()]
    while consumeSymbol(",") {
      permissions.append(try permission())
    }
    try expectKeyword("TO")
    let role = try identifier(describing: "a role name").name
    return SchemaGrant(permissions: permissions, role: role)
  }

  private mutating func permission() throws -> SchemaPermission {
    guard let keyword = current.keyword, let permission = SchemaPermission(rawValue: keyword)
    else {
      throw unexpected(expecting: "READ, CREATE or WRITE")
    }
    advance()
    return permission
  }
}
