//
//  FilterBuilder+ListMemberFilters.swift
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

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension FilterBuilder {
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
