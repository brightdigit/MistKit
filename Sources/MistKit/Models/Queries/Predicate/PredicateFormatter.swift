//
//  PredicateFormatter.swift
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

/// Writes conditions in the canonical predicate syntax, one per line.
internal enum PredicateFormatter {
  internal static func format(
    _ conditions: [QueryDescriptor.Condition]
  ) throws(QueryPredicateFormatError) -> String {
    var lines: [String] = []
    for condition in conditions {
      lines.append(try line(condition))
    }
    return lines.joined(separator: "\nAND ")
  }

  private static func line(
    _ condition: QueryDescriptor.Condition
  ) throws(QueryPredicateFormatError) -> String {
    let name = condition.fieldName
    let field = PredicateKeywords.needsEscape(name) ? "#\(name)" : name
    let comparator = condition.comparator.filterComparator
    guard let value = literal(condition.value, takesList: condition.comparator.takesList)
    else {
      throw .unrepresentableValue(fieldName: name)
    }
    if case .near(let meters) = condition.comparator {
      guard let kilometres = PredicateLiteral.number(meters / 1_000) else {
        throw .unrepresentableValue(fieldName: name)
      }
      return "distanceToLocation:fromLocation:(\(field), \(value)) < \(kilometres)"
    }
    guard let spelling = PredicateKeywords.spellings[comparator] else {
      throw .unrepresentableComparator(fieldName: name, comparator: comparator)
    }
    return "\(field) \(spelling) \(value)"
  }

  /// The value's literal; a `{…}` list for `IN`.
  private static func literal(_ value: FieldValue, takesList: Bool) -> String? {
    guard takesList else {
      return value.predicateLiteral
    }
    guard let elements = value.listElements, !elements.isEmpty else {
      return nil
    }
    let literals = elements.compactMap(\.predicateLiteral)
    guard literals.count == elements.count else {
      return nil
    }
    return "{" + literals.joined(separator: ", ") + "}"
  }
}
