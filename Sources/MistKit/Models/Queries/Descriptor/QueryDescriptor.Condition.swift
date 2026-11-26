//
//  QueryDescriptor.Condition.swift
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

extension QueryDescriptor {
  /// One condition of a query: a field, a comparator and the value to compare
  /// with.
  ///
  /// The value is coded as ``FieldValue`` codes itself: a CloudKit field
  /// dictionary with its `type` (`{"value": …, "type": "TIMESTAMP"}`).
  public struct Condition: Hashable, Codable, Sendable {
    /// The field to filter on.
    public var fieldName: String
    /// How to compare the field with ``value``.
    public var comparator: Comparator
    /// The value to compare with: a single value, or a list for
    /// ``Comparator/in`` and ``Comparator/notIn``.
    public var value: FieldValue

    /// Creates a condition.
    /// - Parameters:
    ///   - fieldName: The field to filter on.
    ///   - comparator: How to compare the field with `value`.
    ///   - value: The value to compare with.
    public init(fieldName: String, comparator: Comparator, value: FieldValue) {
      self.fieldName = fieldName
      self.comparator = comparator
      self.value = value
    }
  }
}
