//
//  QueryDescriptor.Condition+Filter.swift
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

extension QueryDescriptor.Condition {
  // swiftlint:disable cyclomatic_complexity
  /// The filter CloudKit receives for this condition.
  ///
  /// A condition on ``QueryDescriptor/recordIDFieldName`` sends `STRING`
  /// values as references. References compare by record name and zone only;
  /// a `NEAR` center by latitude, longitude and accuracy only.
  /// - Throws: ``QueryDescriptorError`` when the value doesn't fit the
  ///   comparator.
  public func filter() throws(QueryDescriptorError) -> QueryFilter {
    let operand = QueryOperand(value, isRecordID: fieldName == QueryDescriptor.recordIDFieldName)
    switch comparator {
    case .beginsWith, .notBeginsWith, .containsAllTokens, .containsAnyTokens,
      .listMemberBeginsWith, .notListMemberBeginsWith:
      guard let text = operand.value.stringValue else {
        throw .valueMismatch(fieldName: fieldName, comparator: comparator.filterComparator)
      }
      return textFilter(text)
    case .near(let meters):
      guard let center = operand.nearCenter else {
        throw .valueMismatch(fieldName: fieldName, comparator: .near)
      }
      return .near(fieldName, center, distance: meters)
    case .in, .notIn:
      guard let elements = operand.listElements else {
        throw .unsupportedValue(fieldName: fieldName)
      }
      return comparator == .in ? .in(fieldName, elements) : .notIn(fieldName, elements)
    default:
      guard let scalar = operand.scalar else {
        throw .unsupportedValue(fieldName: fieldName)
      }
      return scalarFilter(scalar)
    }
  }
  // swiftlint:enable cyclomatic_complexity

  private func textFilter(_ text: String) -> QueryFilter {
    switch comparator {
    case .notBeginsWith: .notBeginsWith(fieldName, text)
    case .containsAllTokens: .containsAllTokens(fieldName, text)
    case .containsAnyTokens: .containsAnyTokens(fieldName, text)
    case .listMemberBeginsWith: .listMemberBeginsWith(fieldName, text)
    case .notListMemberBeginsWith: .notListMemberBeginsWith(fieldName, text)
    default: .beginsWith(fieldName, text)
    }
  }

  // swiftlint:disable:next cyclomatic_complexity
  private func scalarFilter(_ value: FieldValue) -> QueryFilter {
    switch comparator {
    case .notEquals: .notEquals(fieldName, value)
    case .lessThan: .lessThan(fieldName, value)
    case .lessThanOrEquals: .lessThanOrEquals(fieldName, value)
    case .greaterThan: .greaterThan(fieldName, value)
    case .greaterThanOrEquals: .greaterThanOrEquals(fieldName, value)
    case .listContains: .listContains(fieldName, value)
    case .notListContains: .notListContains(fieldName, value)
    default: .equals(fieldName, value)
    }
  }
}
