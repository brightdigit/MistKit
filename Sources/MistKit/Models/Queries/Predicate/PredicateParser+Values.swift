//
//  PredicateParser+Values.swift
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

extension PredicateParser {
  /// `distanceToLocation:fromLocation:(field, LOCATION(lat, lon)) < km`.
  internal mutating func distanceCondition() throws(PredicateSyntaxError) -> Condition {
    try expect("(")
    let field = try fieldName()
    try expect(",")
    let start = current.range
    let value = try value(for: field)
    guard case .location(.value) = value else {
      throw PredicateSyntaxError(
        .expectedLocation,
        start.lowerBound..<previous.range.upperBound
      )
    }
    try expect(")")
    if current.isSymbol("<=") {
      advance()
    } else {
      try expect("<")
    }
    let kilometres = try double(advance())
    let meters = (kilometres * 1_000_000).rounded() / 1_000
    return Condition(fieldName: field, comparator: .near(meters: meters), value: value)
  }

  internal mutating func comparisonValue(
    for comparator: Comparator,
    field: String
  ) throws(PredicateSyntaxError) -> FieldValue {
    switch comparator {
    case .beginsWith:
      return .string(.value(try string(advance())))
    case .in:
      return try list(for: field)
    default:
      return try value(for: field)
    }
  }

  /// A literal: number, string, `CAST("iso", "NSDate")`, `REFERENCE("name")`,
  /// `LOCATION(lat, lon)` or `BYTES("base64")`.
  internal mutating func value(
    for field: String
  ) throws(PredicateSyntaxError) -> FieldValue {
    let token = advance()
    switch token.kind {
    case .number(let text):
      return try number(text, range: token.range, field: field)
    case .string(let text):
      return .string(.value(text))
    case .word(let name) where current.isSymbol("("):
      advance()
      let value = try function(name, range: token.range)
      try expect(")")
      return value
    default:
      throw PredicateSyntaxError(.expectedValue, token.range)
    }
  }

  internal func string(_ token: PredicateToken) throws(PredicateSyntaxError) -> String {
    guard case .string(let text) = token.kind else {
      throw PredicateSyntaxError(.expectedString, token.range)
    }
    return text
  }

  internal func double(_ token: PredicateToken) throws(PredicateSyntaxError) -> Double {
    guard case .number(let text) = token.kind, let number = Double(text) else {
      throw PredicateSyntaxError(.expectedNumber, token.range)
    }
    return number
  }

  private func number(
    _ text: String,
    range: Range<Int>,
    field: String
  ) throws(PredicateSyntaxError) -> FieldValue {
    let isWhole = !text.contains { $0 == "." || $0 == "e" || $0 == "E" }
    let wantsDouble = fieldType(of: field)?.elementType == .double
    if isWhole, !wantsDouble {
      guard let integer = Int(text) else {
        throw PredicateSyntaxError(.invalidNumber(text), range)
      }
      return .int64(.value(integer))
    }
    guard let double = Double(text), double.isFinite else {
      throw PredicateSyntaxError(.invalidNumber(text), range)
    }
    return .double(.value(double))
  }
}
