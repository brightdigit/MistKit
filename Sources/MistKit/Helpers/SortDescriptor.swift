//
//  SortDescriptor.swift
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

/// A builder for constructing CloudKit query sort descriptors
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
internal struct SortDescriptor {
  // MARK: - Lifecycle

  private init() {}

  // MARK: - Public

  /// Creates an ascending sort descriptor
  /// - Parameter field: The field name to sort by
  /// - Returns: A configured Sort
  internal static func ascending(_ field: String) -> Components.Schemas.Sort {
    .init(fieldName: field, ascending: true)
  }

  /// Creates a descending sort descriptor
  /// - Parameter field: The field name to sort by
  /// - Returns: A configured Sort
  internal static func descending(_ field: String) -> Components.Schemas.Sort {
    .init(fieldName: field, ascending: false)
  }

  /// Creates a sort descriptor with explicit direction
  /// - Parameters:
  ///   - field: The field name to sort by
  ///   - ascending: Whether to sort in ascending order
  /// - Returns: A configured Sort
  internal static func sort(_ field: String, ascending: Bool = true) -> Components.Schemas.Sort {
    .init(fieldName: field, ascending: ascending)
  }
}
