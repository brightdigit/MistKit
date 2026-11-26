//
//  PredicateKeywords.swift
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

/// Reserved words and operators of the predicate syntax.
internal enum PredicateKeywords {
  /// Words that can't be an unescaped field name; write `#word` instead.
  ///
  /// NSPredicate's reserved words, compared uppercased.
  internal static let reserved: Set<String> = [
    "AND", "OR", "NOT", "BEGINSWITH", "CONTAINS", "ENDSWITH", "LIKE", "MATCHES", "IN",
    "BETWEEN", "ANY", "ALL", "SOME", "NONE", "NULL", "NIL", "SELF", "TRUE", "FALSE",
    "YES", "NO", "TRUEPREDICATE", "FALSEPREDICATE", "FIRST", "LAST", "SIZE",
  ]

  /// The comparison operators written as symbols, with their aliases.
  internal static let symbolComparators: [String: QueryDescriptor.Comparator] = [
    "=": .equals, "==": .equals, "!=": .notEquals, "<>": .notEquals,
    "<": .lessThan, "<=": .lessThanOrEquals, "=<": .lessThanOrEquals,
    ">": .greaterThan, ">=": .greaterThanOrEquals, "=>": .greaterThanOrEquals,
  ]

  /// The comparison operators written as words, uppercased.
  internal static let wordComparators: [String: QueryDescriptor.Comparator] = [
    "BEGINSWITH": .beginsWith, "CONTAINS": .listContains, "IN": .in,
  ]

  /// The canonical spelling of each comparator the syntax can express, except
  /// `NEAR`, which is written `distanceToLocation:fromLocation:(…) < km`.
  internal static let spellings: [FilterComparator: String] = [
    .equals: "=", .notEquals: "!=", .lessThan: "<", .lessThanOrEquals: "<=",
    .greaterThan: ">", .greaterThanOrEquals: ">=", .beginsWith: "BEGINSWITH",
    .listContains: "CONTAINS", .in: "IN",
  ]

  /// Operator and punctuation symbols, longest first so `<=` wins over `<`.
  internal static let symbols: [String] = [
    "==", "!=", "<>", "<=", "=<", ">=", "=>", "&&", "||",
    "=", "<", ">", "!", "(", ")", ",", "{", "}",
  ]

  /// Whether `name` must be written `#name`.
  internal static func needsEscape(_ name: String) -> Bool {
    reserved.contains(name.uppercased())
  }
}
