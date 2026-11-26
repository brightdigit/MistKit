//
//  SchemaFieldType+FieldType.swift
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

extension SchemaFieldType {
  private static let primitives: [FieldType: SchemaPrimitiveType] = [
    .string: .string, .int64: .int64, .double: .double, .timestamp: .timestamp,
    .bytes: .bytes, .reference: .reference, .asset: .asset, .location: .location,
  ]

  /// The type values of this field carry.
  ///
  /// `ENCRYPTED` is dropped, and `NUMBER` is `INT64` when it's
  /// `PREFERRED AS INT64` and `DOUBLE` otherwise, since a double holds either
  /// kind of number.
  public var resolved: FieldType {
    let element: FieldType =
      switch primitive {
      case .asset: .asset
      case .bytes: .bytes
      case .double, .number(preferredAs: .double), .number(preferredAs: nil): .double
      case .int64, .number(preferredAs: .int64): .int64
      case .location: .location
      case .reference: .reference
      case .string: .string
      case .timestamp: .timestamp
      }
    return isList ? .list(element) : element
  }

  /// The unencrypted schema type for a field type.
  ///
  /// A nested list keeps its innermost element type, since the language has no
  /// `LIST<LIST<…>>`.
  public init(_ fieldType: FieldType) {
    switch fieldType {
    case .list(let element):
      self.init(Self.primitive(innermost: element), isList: true)
    default:
      self.init(Self.primitive(innermost: fieldType))
    }
  }

  private static func primitive(innermost fieldType: FieldType) -> SchemaPrimitiveType {
    if case .list(let element) = fieldType {
      return primitive(innermost: element)
    }
    return primitives[fieldType] ?? .string
  }
}

extension SchemaField: Identifiable {
  /// The field's name, unique within its record type.
  public var id: String { name }

  /// The type the field's values carry: ``SchemaFieldType/resolved``.
  public var resolvedType: FieldType { type.resolved }
}
