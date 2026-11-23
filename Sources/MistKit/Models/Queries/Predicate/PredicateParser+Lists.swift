//
//  PredicateParser+Lists.swift
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
  /// `elements` with integers as doubles when any element is a double.
  private static func widened(_ elements: [FieldValue]) -> [FieldValue] {
    guard elements.contains(where: { $0.fieldType == .double }) else {
      return elements
    }
    return elements.map { element in
      element.intValue.map { .double(.value(Double($0))) } ?? element
    }
  }

  /// `{value, …}`, the list `IN` compares with.
  ///
  /// Whole numbers in a list with fractional ones are read as doubles. An
  /// empty list takes the field's type, so needs the record type.
  internal mutating func list(for field: String) throws(PredicateSyntaxError) -> FieldValue {
    let start = current.range.lowerBound
    try expect("{")
    var elements: [FieldValue] = []
    if current.isSymbol("}") {
      advance()
    } else {
      elements.append(try value(for: field))
      while !current.isSymbol("}") {
        try expect(",")
        elements.append(try value(for: field))
      }
      advance()
    }
    let range = start..<previous.range.upperBound
    guard !elements.isEmpty else {
      guard let element = fieldType(of: field)?.elementType,
        let empty = FieldValue.emptyList(of: element)
      else {
        throw PredicateSyntaxError(.untypedEmptyList, range)
      }
      return empty
    }
    guard let list = FieldValue.list(of: Self.widened(elements)) else {
      throw PredicateSyntaxError(.mixedList, range)
    }
    return list
  }
}
