//
//  QueryFilter.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Public wrapper for CloudKit query filters
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
public struct QueryFilter {
  // MARK: - Lifecycle

  private init(_ filter: Components.Schemas.Filter) {
    self.filter = filter
  }

  // MARK: - Public

  // MARK: Equality Filters

  /// Creates an EQUALS filter
  public static func equals(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.equals(field, value))
  }

  /// Creates a NOT_EQUALS filter
  public static func notEquals(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.notEquals(field, value))
  }

  // MARK: Comparison Filters

  /// Creates a LESS_THAN filter
  public static func lessThan(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.lessThan(field, value))
  }

  /// Creates a LESS_THAN_OR_EQUALS filter
  public static func lessThanOrEquals(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.lessThanOrEquals(field, value))
  }

  /// Creates a GREATER_THAN filter
  public static func greaterThan(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.greaterThan(field, value))
  }

  /// Creates a GREATER_THAN_OR_EQUALS filter
  public static func greaterThanOrEquals(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.greaterThanOrEquals(field, value))
  }

  // MARK: String Filters

  /// Creates a BEGINS_WITH filter for string fields
  public static func beginsWith(_ field: String, _ value: String) -> QueryFilter {
    QueryFilter(FilterBuilder.beginsWith(field, value))
  }

  /// Creates a NOT_BEGINS_WITH filter for string fields
  public static func notBeginsWith(_ field: String, _ value: String) -> QueryFilter {
    QueryFilter(FilterBuilder.notBeginsWith(field, value))
  }

  /// Creates a CONTAINS_ALL_TOKENS filter for string fields
  public static func containsAllTokens(_ field: String, _ tokens: String) -> QueryFilter {
    QueryFilter(FilterBuilder.containsAllTokens(field, tokens))
  }

  /// Creates an IN filter to check if field value is in a list
  public static func `in`(_ field: String, _ values: [FieldValue]) -> QueryFilter {
    QueryFilter(FilterBuilder.in(field, values))
  }

  /// Creates a NOT_IN filter to check if field value is not in a list
  public static func notIn(_ field: String, _ values: [FieldValue]) -> QueryFilter {
    QueryFilter(FilterBuilder.notIn(field, values))
  }

  // MARK: List Member Filters

  /// Creates a LIST_CONTAINS filter
  public static func listContains(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.listContains(field, value))
  }

  /// Creates a NOT_LIST_CONTAINS filter
  public static func notListContains(_ field: String, _ value: FieldValue) -> QueryFilter {
    QueryFilter(FilterBuilder.notListContains(field, value))
  }

  /// Creates a LIST_MEMBER_BEGINS_WITH filter
  public static func listMemberBeginsWith(_ field: String, _ prefix: String) -> QueryFilter {
    QueryFilter(FilterBuilder.listMemberBeginsWith(field, prefix))
  }

  /// Creates a NOT_LIST_MEMBER_BEGINS_WITH filter
  public static func notListMemberBeginsWith(_ field: String, _ prefix: String) -> QueryFilter {
    QueryFilter(FilterBuilder.notListMemberBeginsWith(field, prefix))
  }

  // MARK: - Internal

  internal let filter: Components.Schemas.Filter
}
