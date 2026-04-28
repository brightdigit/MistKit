//
//  FilterBuilder+StringFilters.swift
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
}
