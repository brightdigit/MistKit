//
//  FilterBuilder.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// A builder for constructing CloudKit query filters
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
internal struct FilterBuilder {
  // MARK: - Lifecycle

  private init() {}

  // MARK: - Internal

  // MARK: Equality Filters

  /// Creates an EQUALS filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func equals(_ field: String, _ value: FieldValue) -> Components.Schemas.Filter {
    .init(
      comparator: .EQUALS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a NOT_EQUALS filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func notEquals(_ field: String, _ value: FieldValue) -> Components.Schemas.Filter
  {
    .init(
      comparator: .NOT_EQUALS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  // MARK: Comparison Filters

  /// Creates a LESS_THAN filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func lessThan(_ field: String, _ value: FieldValue) -> Components.Schemas.Filter {
    .init(
      comparator: .LESS_THAN,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a LESS_THAN_OR_EQUALS filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func lessThanOrEquals(
    _ field: String,
    _ value: FieldValue
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .LESS_THAN_OR_EQUALS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a GREATER_THAN filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func greaterThan(
    _ field: String,
    _ value: FieldValue
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .GREATER_THAN,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a GREATER_THAN_OR_EQUALS filter
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The value to compare
  /// - Returns: A configured Filter
  internal static func greaterThanOrEquals(
    _ field: String,
    _ value: FieldValue
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .GREATER_THAN_OR_EQUALS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  // MARK: String Filters

  /// Creates a BEGINS_WITH filter for string fields
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The prefix value to match
  /// - Returns: A configured Filter
  internal static func beginsWith(_ field: String, _ value: String) -> Components.Schemas.Filter {
    .init(
      comparator: .BEGINS_WITH,
      fieldName: field,
      fieldValue: .init(value: .StringValue(value))
    )
  }

  /// Creates a NOT_BEGINS_WITH filter for string fields
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - value: The prefix value to not match
  /// - Returns: A configured Filter
  internal static func notBeginsWith(_ field: String, _ value: String) -> Components.Schemas.Filter
  {
    .init(
      comparator: .NOT_BEGINS_WITH,
      fieldName: field,
      fieldValue: .init(value: .StringValue(value))
    )
  }

  /// Creates a CONTAINS_ALL_TOKENS filter for string fields
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - tokens: The string containing all tokens that must be present
  /// - Returns: A configured Filter
  internal static func containsAllTokens(
    _ field: String,
    _ tokens: String
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .CONTAINS_ALL_TOKENS,
      fieldName: field,
      fieldValue: .init(value: .StringValue(tokens))
    )
  }

  /// Creates an IN filter to check if field value is in a list
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - values: Array of values to match against
  /// - Returns: A configured Filter
  internal static func `in`(_ field: String, _ values: [FieldValue]) -> Components.Schemas.Filter {
    .init(
      comparator: .IN,
      fieldName: field,
      fieldValue: .init(
        value: .ListValue(values.map { Components.Schemas.FieldValueRequest.convertToListValuePayload($0) })
      )
    )
  }

  /// Creates a NOT_IN filter to check if field value is not in a list
  /// - Parameters:
  ///   - field: The field name to filter on
  ///   - values: Array of values to exclude
  /// - Returns: A configured Filter
  internal static func notIn(_ field: String, _ values: [FieldValue]) -> Components.Schemas.Filter {
    .init(
      comparator: .NOT_IN,
      fieldName: field,
      fieldValue: .init(
        value: .ListValue(values.map { Components.Schemas.FieldValueRequest.convertToListValuePayload($0) })
      )
    )
  }

  // MARK: List Member Filters

  /// Creates a LIST_CONTAINS filter
  /// - Parameters:
  ///   - field: The list field name to filter on
  ///   - value: The value that should be in the list
  /// - Returns: A configured Filter
  internal static func listContains(
    _ field: String,
    _ value: FieldValue
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .LIST_CONTAINS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a NOT_LIST_CONTAINS filter
  /// - Parameters:
  ///   - field: The list field name to filter on
  ///   - value: The value that should not be in the list
  /// - Returns: A configured Filter
  internal static func notListContains(
    _ field: String,
    _ value: FieldValue
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .NOT_LIST_CONTAINS,
      fieldName: field,
      fieldValue: .init(from: value)
    )
  }

  /// Creates a LIST_MEMBER_BEGINS_WITH filter
  /// - Parameters:
  ///   - field: The list field name to filter on
  ///   - prefix: The prefix that list members should begin with
  /// - Returns: A configured Filter
  internal static func listMemberBeginsWith(
    _ field: String,
    _ prefix: String
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .LIST_MEMBER_BEGINS_WITH,
      fieldName: field,
      fieldValue: .init(value: .StringValue(prefix))
    )
  }

  /// Creates a NOT_LIST_MEMBER_BEGINS_WITH filter
  /// - Parameters:
  ///   - field: The list field name to filter on
  ///   - prefix: The prefix that list members should not begin with
  /// - Returns: A configured Filter
  internal static func notListMemberBeginsWith(
    _ field: String,
    _ prefix: String
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .NOT_LIST_MEMBER_BEGINS_WITH,
      fieldName: field,
      fieldValue: .init(value: .StringValue(prefix))
    )
  }
}
