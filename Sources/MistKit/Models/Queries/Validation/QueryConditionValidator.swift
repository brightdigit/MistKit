//
//  QueryConditionValidator.swift
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

/// Checks one condition against its record type.
internal struct QueryConditionValidator {
  internal let recordType: SchemaRecordType
  internal let checksIndexes: Bool

  /// The value types a field accepts with `comparator`: its element type,
  /// both number types for `NUMBER`, record names or references for
  /// `___recordID`, and lists of those for `IN` and `NOT_IN`.
  private static func acceptedTypes(
    for field: SchemaField,
    comparator: QueryDescriptor.Comparator
  ) -> [FieldType] {
    let elements: [FieldType]
    if field.name == QueryDescriptor.recordIDFieldName {
      elements = [.string, .reference]
    } else if case .number = field.type.primitive {
      elements = [.int64, .double]
    } else {
      elements = [field.resolvedType.elementType]
    }
    return comparator.takesList ? elements.map { .list($0) } : elements
  }

  /// The issues with the condition at `index`, most fundamental first.
  internal func issues(
    for condition: QueryDescriptor.Condition,
    at index: Int
  ) -> [QueryValidationIssue] {
    let name = condition.fieldName
    guard let field = recordType.queryField(named: name) else {
      return checksIndexes ? [.unknownField(name, target: .condition(index))] : []
    }
    let comparator = condition.comparator.filterComparator
    var issues = checksIndexes ? indexIssues(field, comparator: comparator, at: index) : []
    guard field.type.allowedComparators.contains(comparator) else {
      return issues + [.unsupportedComparator(comparator, field: field, condition: index)]
    }
    if checksIndexes, comparator.requiresSortableIndex, !field.isSortable {
      issues.append(.notSortable(name, target: .condition(index)))
    }
    let valueType = condition.value.fieldType
    if !Self.acceptedTypes(for: field, comparator: condition.comparator).contains(valueType) {
      issues.append(.valueMismatch(field: field, valueType: valueType, condition: index))
    }
    return issues
  }

  private func indexIssues(
    _ field: SchemaField,
    comparator: FilterComparator,
    at index: Int
  ) -> [QueryValidationIssue] {
    if comparator.requiresSearchableIndex {
      return field.isSearchable ? [] : [.notSearchable(field.name, condition: index)]
    }
    return field.isQueryable ? [] : [.notQueryable(field.name, condition: index)]
  }
}
