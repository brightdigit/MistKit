//
//  PredicateParser.swift
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

/// Reads conditions joined by `AND` from predicate tokens.
internal struct PredicateParser {
  internal typealias Condition = QueryDescriptor.Condition
  internal typealias Comparator = QueryDescriptor.Comparator

  internal let tokens: [PredicateToken]
  internal let recordType: SchemaRecordType?
  internal var position = 0

  internal var current: PredicateToken { tokens[position] }

  /// The token before ``current``, or ``current`` at the start.
  internal var previous: PredicateToken { tokens[max(position - 1, 0)] }

  internal init(tokens: [PredicateToken], recordType: SchemaRecordType?) {
    self.tokens = tokens
    self.recordType = recordType
  }

  private static func connective(_ token: PredicateToken) -> PredicateSyntaxError {
    let spelling = token.keyword ?? (token.isSymbol("||") ? "||" : "!")
    return PredicateSyntaxError(.unsupportedConnective(spelling), token.range)
  }

  /// Every condition; empty text and `TRUEPREDICATE` have none.
  internal mutating func parse() throws(PredicateSyntaxError) -> [Condition] {
    if current.kind == .end {
      return []
    }
    if current.keyword == "TRUEPREDICATE", tokens[position + 1].kind == .end {
      return []
    }
    var conditions = [try condition()]
    while current.kind != .end {
      let token = advance()
      if token.keyword == "AND" || token.isSymbol("&&") {
        conditions.append(try condition())
      } else if token.keyword == "OR" || token.isSymbol("||") {
        throw Self.connective(token)
      } else {
        throw PredicateSyntaxError(.expectedConnective, token.range)
      }
    }
    return conditions
  }

  @discardableResult
  internal mutating func advance() -> PredicateToken {
    let token = current
    if token.kind != .end {
      position += 1
    }
    return token
  }

  internal mutating func expect(_ symbol: String) throws(PredicateSyntaxError) {
    let token = advance()
    guard token.isSymbol(symbol) else {
      throw PredicateSyntaxError(.expectedToken(symbol), token.range)
    }
  }

  internal mutating func fieldName() throws(PredicateSyntaxError) -> String {
    let token = advance()
    switch token.kind {
    case .escapedField(let name):
      return name
    case .word(let name) where !PredicateKeywords.needsEscape(name):
      return name
    case .word where token.keyword == "NOT", .symbol("!"):
      throw Self.connective(token)
    default:
      throw PredicateSyntaxError(.expectedField, token.range)
    }
  }

  /// The schema type of `field`, when the record type is known.
  internal func fieldType(of field: String) -> FieldType? {
    recordType?.queryField(named: field)?.resolvedType
  }

  private mutating func condition() throws(PredicateSyntaxError) -> Condition {
    if current.kind == .distanceFunction {
      advance()
      return try distanceCondition()
    }
    let field = try fieldName()
    let comparator = try comparator()
    let value = try comparisonValue(for: comparator, field: field)
    return Condition(fieldName: field, comparator: comparator, value: value)
  }

  private mutating func comparator() throws(PredicateSyntaxError) -> Comparator {
    let token = advance()
    if case .symbol(let symbol) = token.kind,
      let comparator = PredicateKeywords.symbolComparators[symbol]
    {
      return comparator
    }
    if let keyword = token.keyword, let comparator = PredicateKeywords.wordComparators[keyword] {
      return comparator
    }
    throw PredicateSyntaxError(.expectedOperator, token.range)
  }
}
