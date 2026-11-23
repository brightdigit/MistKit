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
  /// The value is encoded as a CloudKit field dictionary that always carries
  /// its `type` (`{"value": …, "type": "TIMESTAMP"}`, see ``WireFieldValue``),
  /// because ``FieldValue``'s own coding is untagged and would read a
  /// timestamp back as a number.
  public struct Condition: Hashable, Codable, Sendable {
    private enum CodingKeys: String, CodingKey {
      case fieldName
      case comparator
      case value
    }

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

    /// Decodes a condition; a cleared value (`{"value": null}`) is an error.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      fieldName = try container.decode(String.self, forKey: .fieldName)
      comparator = try container.decode(Comparator.self, forKey: .comparator)
      let wire = try container.decode(WireFieldValue.self, forKey: .value)
      guard let value = wire.value else {
        throw DecodingError.dataCorruptedError(
          forKey: .value,
          in: container,
          debugDescription: "A condition needs a value."
        )
      }
      self.value = value
    }

    /// Encodes the condition, tagging the value with its type.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: CodingKeys.self)
      try container.encode(fieldName, forKey: .fieldName)
      try container.encode(comparator, forKey: .comparator)
      try container.encode(WireFieldValue(value, typeTagging: .always), forKey: .value)
    }
  }
}
