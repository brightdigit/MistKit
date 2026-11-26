//
//  SchemaFieldType.swift
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

/// A field's data type in CloudKit Schema Language.
///
/// Mirrors the grammar's `data-type`: a primitive type, optionally
/// `ENCRYPTED`, optionally wrapped in `LIST<…>`.
public struct SchemaFieldType: Sendable, Hashable, Codable {
  /// The primitive (element) type.
  public var primitive: SchemaPrimitiveType
  /// Whether the value is declared `ENCRYPTED`.
  public var isEncrypted: Bool
  /// Whether the field is a `LIST<…>` of ``primitive``.
  public var isList: Bool

  /// The type as the language writes it, such as `LIST<ENCRYPTED STRING>`.
  public var schemaText: String {
    let element = isEncrypted ? "ENCRYPTED \(primitive.schemaText)" : primitive.schemaText
    return isList ? "LIST<\(element)>" : element
  }

  /// Creates a field type.
  public init(
    _ primitive: SchemaPrimitiveType,
    isEncrypted: Bool = false,
    isList: Bool = false
  ) {
    self.primitive = primitive
    self.isEncrypted = isEncrypted
    self.isList = isList
  }
}
