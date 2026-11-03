//
//  SchemaParser+DataTypes.swift
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

extension SchemaParser {
  /// Primitive type keywords that take no further clauses.
  private static let simplePrimitives: [String: SchemaPrimitiveType] = [
    "ASSET": .asset,
    "BYTES": .bytes,
    "DOUBLE": .double,
    "INT64": .int64,
    "LOCATION": .location,
    "REFERENCE": .reference,
    "STRING": .string,
    "TIMESTAMP": .timestamp,
  ]

  /// `data-type`: a primitive type, optionally wrapped in `LIST<…>`.
  internal mutating func dataType() throws -> SchemaFieldType {
    if current.isKeyword("LIST") {
      advance()
      try expectSymbol("<")
      let (primitive, isEncrypted) = try primitiveType()
      try expectSymbol(">")
      return SchemaFieldType(primitive, isEncrypted: isEncrypted, isList: true)
    }
    let (primitive, isEncrypted) = try primitiveType()
    return SchemaFieldType(primitive, isEncrypted: isEncrypted)
  }

  /// `primitive-type`, with an optional leading `ENCRYPTED`.
  private mutating func primitiveType() throws -> (SchemaPrimitiveType, Bool) {
    let isEncrypted = current.isKeyword("ENCRYPTED")
    if isEncrypted {
      advance()
    }
    guard case .word(let word) = current.kind else {
      throw unexpected(expecting: "a data type")
    }
    let keyword = word.uppercased()
    if keyword == "NUMBER" {
      advance()
      return (.number(preferredAs: try numberPreference()), isEncrypted)
    }
    guard let primitive = Self.simplePrimitives[keyword] else {
      throw unexpected(expecting: "a data type")
    }
    advance()
    return (primitive, isEncrypted)
  }

  /// An optional `PREFERRED AS { INT64 | DOUBLE }` after `NUMBER`.
  private mutating func numberPreference() throws -> SchemaNumberPreference? {
    guard current.isKeyword("PREFERRED") else {
      return nil
    }
    advance()
    try expectKeyword("AS")
    guard
      case .word(let word) = current.kind,
      let preference = SchemaNumberPreference(rawValue: word.uppercased())
    else {
      throw unexpected(expecting: "INT64 or DOUBLE")
    }
    advance()
    return preference
  }
}
