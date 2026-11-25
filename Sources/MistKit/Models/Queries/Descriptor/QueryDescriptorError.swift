//
//  QueryDescriptorError.swift
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

/// Why a ``QueryDescriptor`` can't become a ``Query``.
///
/// ``QueryDescriptor/validate(against:checksIndexes:)`` reports each of these
/// against a schema, so a query that validates cleanly never throws them.
public enum QueryDescriptorError: LocalizedError, Hashable, Sendable {
  /// The value's type doesn't fit the comparator, for example `BEGINS_WITH` 3
  /// or `NEAR` a string.
  case valueMismatch(fieldName: String, comparator: FilterComparator)
  /// The value can't be compared at all: assets, and lists outside `IN` and
  /// `NOT_IN`.
  case unsupportedValue(fieldName: String)

  /// The field whose condition failed.
  public var fieldName: String {
    switch self {
    case .valueMismatch(let fieldName, _), .unsupportedValue(let fieldName):
      fieldName
    }
  }

  /// A description of the error.
  public var errorDescription: String? {
    switch self {
    case .valueMismatch(let fieldName, let comparator):
      "\(comparator.rawValue) on \(fieldName) can't take this value"
    case .unsupportedValue(let fieldName):
      "The value for \(fieldName) can't be used in a filter"
    }
  }
}
