//
//  FieldValue+ListElements.swift
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

extension FieldValue {
  /// Whether this is a list value, empty or not.
  public var isList: Bool { fieldType.isList }

  /// The elements of a list value as single values; `nil` for a single value.
  public var listElements: [FieldValue]? {
    switch self {
    case .string(.list(let values)): values.map { .string(.value($0)) }
    case .int64(.list(let values)): values.map { .int64(.value($0)) }
    case .double(.list(let values)): values.map { .double(.value($0)) }
    case .bytes(.list(let values)): values.map { .bytes(.value($0)) }
    case .date(.list(let values)): values.map { .date(.value($0)) }
    case .location(.list(let values)): values.map { .location(.value($0)) }
    case .reference(.list(let values)): values.map { .reference(.value($0)) }
    case .asset(.list(let values)): values.map { .asset(.value($0)) }
    default: nil
    }
  }

  // swiftlint:disable cyclomatic_complexity
  /// An empty list typed from a field's type.
  ///
  /// CloudKit lists carry their element type even when empty, so an empty
  /// list can only be built when the type is known.
  ///
  /// - Parameter type: A list type (`LIST<STRING>`) or its element type
  ///   (`STRING`).
  /// - Returns: The empty list, or `nil` for a nested list type.
  public static func emptyList(of type: FieldType) -> FieldValue? {
    switch type.elementType {
    case .string: .string(.list([]))
    case .int64: .int64(.list([]))
    case .double: .double(.list([]))
    case .bytes: .bytes(.list([]))
    case .timestamp: .date(.list([]))
    case .location: .location(.list([]))
    case .reference: .reference(.list([]))
    case .asset: .asset(.list([]))
    case .list: nil
    }
  }
  // swiftlint:enable cyclomatic_complexity

  /// A list of single `elements`, all of one kind.
  ///
  /// - Parameter elements: Single values of one kind.
  /// - Returns: The list, or `nil` when `elements` is empty (the element type
  ///   is unknown), mixes kinds or holds a list.
  public static func list(of elements: [FieldValue]) -> FieldValue? {
    guard let first = elements.first?.fieldType, !first.isList,
      elements.allSatisfy({ $0.fieldType == first })
    else {
      return nil
    }
    return list(sameKind: elements, of: first)
  }

  // swiftlint:disable:next cyclomatic_complexity
  private static func list(sameKind elements: [FieldValue], of type: FieldType) -> FieldValue? {
    switch type {
    case .string: .string(.list(elements.compactMap(\.stringValue)))
    case .int64: .int64(.list(elements.compactMap(\.intValue)))
    case .double: .double(.list(elements.compactMap(\.doubleValue)))
    case .bytes: .bytes(.list(elements.compactMap(\.dataValue)))
    case .timestamp: .date(.list(elements.compactMap(\.dateValue)))
    case .location: .location(.list(elements.compactMap(\.locationValue)))
    case .reference: .reference(.list(elements.compactMap(\.referenceValue)))
    case .asset: .asset(.list(elements.compactMap(\.assetValue)))
    case .list: nil
    }
  }
}
