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
internal struct SchemaParser {
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

    var roles: [String] = []
    var recordTypes: [SchemaRecordType] = []
    while current.kind != .end {
      if current.isKeyword("CREATE") {
        advance()
        try expectKeyword("ROLE")
        roles.append(try identifier(describing: "a role name"))
      } else if current.isKeyword("RECORD") {
        recordTypes.append(try recordType())
      } else {
        throw unexpected(expecting: "CREATE ROLE or RECORD TYPE")
      }
      try expectSymbol(";")
    }
    return CloudKitSchema(roles: roles, recordTypes: recordTypes)
  }

  // MARK: - Statements

  private mutating func recordType() throws -> SchemaRecordType {
    try expectKeyword("RECORD")
    try expectKeyword("TYPE")
    let name = try identifier(describing: "a record type name")
    try expectSymbol("(")

    var fields: [SchemaField] = []
    var grants: [SchemaGrant] = []
    while !isSymbol(")") {
      if current.isKeyword("GRANT") {
        grants.append(try grant())
      } else {
        fields.append(try field())
      }
      guard isSymbol(",") else {
        break
      }
      advance()
    }
    try expectSymbol(")")
    return SchemaRecordType(name: name, fields: fields, grants: grants)
  }

  private mutating func field() throws -> SchemaField {
    let name = try identifier(describing: "a field name or GRANT")
    let type = try dataType()
    var isQueryable = false
    var isSortable = false
    var isSearchable = false
    while case .word = current.kind {
      if current.isKeyword("QUERYABLE") {
        isQueryable = true
      } else if current.isKeyword("SORTABLE") {
        isSortable = true
      } else if current.isKeyword("SEARCHABLE") {
        isSearchable = true
      } else {
        throw unexpected(expecting: "QUERYABLE, SORTABLE, SEARCHABLE, ',' or ')'")
      }
      advance()
    }
    return SchemaField(
      name: name,
      type: type,
      isQueryable: isQueryable,
      isSortable: isSortable,
      isSearchable: isSearchable
    )
  }

  private mutating func grant() throws -> SchemaGrant {
    try expectKeyword("GRANT")
    var permissions: [SchemaPermission] = []
    repeat {
      if !permissions.isEmpty {
        advance()
      }
      guard
        case .word(let word) = current.kind,
        let permission = SchemaPermission(rawValue: word.uppercased())
      else {
        throw unexpected(expecting: "READ, CREATE or WRITE")
      }
      permissions.append(permission)
      advance()
    } while isSymbol(",") && nextIsPermission()
    try expectKeyword("TO")
    let role = try identifier(describing: "a role name")
    return SchemaGrant(permissions: permissions, role: role)
  }
}
