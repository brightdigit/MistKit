//
//  QueryValidationIssue+Target.swift
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

extension QueryValidationIssue {
  /// The part of the query this issue is about.
  public var target: Target {
    switch self {
    case .unknownRecordType, .limitOutOfRange, .indexesUnknown:
      .query
    case .unknownField(_, let target), .notSortable(_, let target):
      target
    case .unknownDesiredKey(_, let index):
      .desiredKey(index)
    case .notQueryable(_, let index), .notSearchable(_, let index),
      .unsupportedComparator(_, _, let index), .valueMismatch(_, _, let index):
      .condition(index)
    }
  }

  /// The field this issue is about, if any.
  public var fieldName: String? {
    switch self {
    case .unknownRecordType, .limitOutOfRange, .indexesUnknown:
      nil
    case .unknownField(let name, _), .unknownDesiredKey(let name, _),
      .notQueryable(let name, _), .notSearchable(let name, _), .notSortable(let name, _):
      name
    case .unsupportedComparator(_, let field, _), .valueMismatch(let field, _, _):
      field.name
    }
  }

  /// Whether CloudKit would reject the query, so it shouldn't be sent.
  ///
  /// Only ``unknownDesiredKey(_:index:)`` and ``indexesUnknown`` don't block.
  public var isBlocking: Bool {
    switch self {
    case .unknownDesiredKey, .indexesUnknown: false
    default: true
    }
  }
}
