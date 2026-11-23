//
//  QueryPredicateFormatError.swift
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

public import Foundation

/// Why conditions can't be written as a predicate format string.
public enum QueryPredicateFormatError: LocalizedError, Hashable, Sendable {
  /// Assets, lists outside `IN`, empty `IN` lists and non-finite numbers have
  /// no literal.
  case unrepresentableValue(fieldName: String)
  /// The comparator has no NSPredicate spelling CloudKit accepts, such as the
  /// negated and token comparators.
  case unrepresentableComparator(fieldName: String, comparator: FilterComparator)

  /// A description of the error.
  public var errorDescription: String? {
    switch self {
    case .unrepresentableValue(let fieldName):
      "The value for \(fieldName) can't be written as a predicate"
    case .unrepresentableComparator(let fieldName, let comparator):
      "\(comparator.rawValue) on \(fieldName) can't be written as a predicate"
    }
  }
}
