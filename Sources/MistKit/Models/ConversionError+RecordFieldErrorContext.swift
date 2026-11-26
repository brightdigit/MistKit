//
//  ConversionError+RecordFieldErrorContext.swift
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

extension ConversionError: RecordFieldErrorContext {
  /// Always `nil`: a conversion error names the field, not its record.
  public var recordName: String? {
    nil
  }

  /// The record field whose value couldn't be converted, for the field-value
  /// cases; `nil` for the others.
  public var fieldName: String? {
    switch self {
    case .unmappableFieldValue(let fieldName, _, _),
      .typeValueMismatch(let fieldName, _, _),
      .unmappableListItem(let fieldName, _),
      .unmappableNestedListItem(let fieldName, _),
      .ambiguousEmptyList(let fieldName),
      .integerOutOfRange(let fieldName, _):
      fieldName
    default:
      nil
    }
  }
}
