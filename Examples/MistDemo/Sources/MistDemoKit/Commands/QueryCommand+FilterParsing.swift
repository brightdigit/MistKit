//
//  QueryCommand+FilterParsing.swift
//  MistDemo
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

import Foundation
import MistKit

extension QueryCommand {
  /// Parse a single filter expression "field:operator:value" into a QueryFilter
  internal static func parseFilter(_ filterString: String) throws -> QueryFilter {
    let components = filterString.split(
      separator: ":", maxSplits: 2, omittingEmptySubsequences: false
    )

    guard components.count == 3 else {
      throw QueryError.invalidFilter(filterString, expected: "field:operator:value")
    }

    let field = String(components[0]).trimmingCharacters(in: .whitespaces)
    let operatorString = String(components[1]).trimmingCharacters(in: .whitespaces)
    let value = String(components[2])

    guard !field.isEmpty else {
      throw QueryError.emptyFieldName(filterString)
    }

    return try buildFilter(field: field, operatorString: operatorString, value: value)
  }

  /// Build a QueryFilter from parsed components.
  internal static func buildFilter(
    field: String,
    operatorString: String,
    value: String
  ) throws -> QueryFilter {
    if let comparison = buildComparisonFilter(
      field: field, operatorString: operatorString, value: value
    ) {
      return comparison
    }
    return try buildSpecialFilter(
      field: field, operatorString: operatorString, value: value
    )
  }

  /// Build comparison-based filters (equals, not equals, greater/less than).
  // swiftlint:disable:next cyclomatic_complexity
  internal static func buildComparisonFilter(
    field: String,
    operatorString: String,
    value: String
  ) -> QueryFilter? {
    switch operatorString.lowercased() {
    case "eq", "equals", "==", "=":
      return .equals(field, inferFieldValue(value))
    case "ne", "not_equals", "!=":
      return .notEquals(field, inferFieldValue(value))
    case "gt", ">":
      return .greaterThan(field, inferFieldValue(value))
    case "gte", ">=":
      return .greaterThanOrEquals(
        field, inferFieldValue(value)
      )
    case "lt", "<":
      return .lessThan(field, inferFieldValue(value))
    case "lte", "<=":
      return .lessThanOrEquals(
        field, inferFieldValue(value)
      )
    default:
      return nil
    }
  }

  /// Build string and list-based filters.
  internal static func buildSpecialFilter(
    field: String,
    operatorString: String,
    value: String
  ) throws -> QueryFilter {
    switch operatorString.lowercased() {
    case "contains", "like":
      return .containsAllTokens(field, value)
    case "begins_with", "starts_with":
      return .beginsWith(field, value)
    case "in":
      let values = value.split(separator: ",").map {
        inferFieldValue(String($0))
      }
      return .in(field, values)
    case "not_in":
      let values = value.split(separator: ",").map {
        inferFieldValue(String($0))
      }
      return .notIn(field, values)
    default:
      throw QueryError.unsupportedOperator(operatorString)
    }
  }

  /// Infer a FieldValue from a string.
  internal static func inferFieldValue(
    _ string: String
  ) -> FieldValue {
    if let intValue = Int64(string) {
      return .int64(Int(intValue))
    }
    if let doubleValue = Double(string) {
      return .double(doubleValue)
    }
    return .string(string)
  }

  /// Check if a field should be included based on field filter
  internal static func shouldIncludeField(_ fieldName: String, fields: [String]?) -> Bool {
    guard let fields = fields, !fields.isEmpty else {
      return true  // Include all fields if no filter specified
    }

    return fields.contains { requestedField in
      fieldName.lowercased() == requestedField.lowercased()
    }
  }
}
