//
//  FilterBuilder.swift
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
internal import MistKitOpenAPI

/// A builder for constructing CloudKit query filters
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
        value: .ListValue(values.map { Components.Schemas.ListValuePayload(from: $0) }),
        _type: cloudKitListType(for: values)
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
        value: .ListValue(values.map { Components.Schemas.ListValuePayload(from: $0) }),
        _type: cloudKitListType(for: values)
      )
    )
  }

  /// Infers the CloudKit list type required by the IN/NOT_IN filter API
  /// (e.g. [.int64] → .INT64_LIST, [.string] → .STRING_LIST).
  private static func cloudKitListType(
    for values: [FieldValue]
  ) -> Components.Schemas.FieldValueRequest._typePayload? {
    guard let first = values.first
    else { return nil }
    return cloudKitListType(for: first)
  }

  /// Maps a single element to the `*_LIST` request type its list requires.
  ///
  /// The `switch` is `default`-free so a new `FieldValue` case has to be classified here
  /// rather than silently emitting no `type` tag.
  private static func cloudKitListType(
    for first: FieldValue
  ) -> Components.Schemas.FieldValueRequest._typePayload? {
    switch first {
    case .string:
      return .STRING_LIST
    case .int64:
      return .INT64_LIST
    case .double:
      return .DOUBLE_LIST
    case .bytes:
      return .BYTES_LIST
    case .date:
      return .TIMESTAMP_LIST
    case .reference:
      return .REFERENCE_LIST
    case .location:
      return .LOCATION_LIST
    case .asset:
      return .ASSET_LIST
    case .list:
      // Nested lists aren't valid in IN/NOT_IN; omit the type and let CloudKit reject
      // rather than emit an undocumented bare "LIST" tag.
      return nil
    }
  }
}
