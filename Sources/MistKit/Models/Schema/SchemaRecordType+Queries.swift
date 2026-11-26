//
//  SchemaRecordType+Queries.swift
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

extension SchemaRecordType {
  /// The field a query can name: a declared field, or one of the
  /// ``SchemaField/implicitSystemFields`` such as `___recordID`.
  /// - Parameter name: The field name.
  /// - Returns: The field, or `nil` if the record type has none of that name.
  public func queryField(named name: String) -> SchemaField? {
    fieldsIncludingImplicit.first { $0.name == name }
  }

  /// The comparators a filter on the field may use; empty for an unknown
  /// field.
  /// - Parameter name: The field name.
  /// - Returns: ``SchemaFieldType/allowedComparators`` for the field's type.
  public func allowedComparators(forField name: String) -> [FilterComparator] {
    queryField(named: name)?.type.allowedComparators ?? []
  }
}
