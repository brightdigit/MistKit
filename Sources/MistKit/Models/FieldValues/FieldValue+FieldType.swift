//
//  FieldValue+FieldType.swift
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
  /// The value's type: `LIST<…>` for a list, empty or not.
  public var fieldType: FieldType {
    let element: FieldType
    let isList: Bool
    switch self {
    case .string(let arity):
      (element, isList) = (.string, arity.isList)
    case .int64(let arity):
      (element, isList) = (.int64, arity.isList)
    case .double(let arity):
      (element, isList) = (.double, arity.isList)
    case .bytes(let arity):
      (element, isList) = (.bytes, arity.isList)
    case .date(let arity):
      (element, isList) = (.timestamp, arity.isList)
    case .location(let arity):
      (element, isList) = (.location, arity.isList)
    case .reference(let arity):
      (element, isList) = (.reference, arity.isList)
    case .asset(let arity):
      (element, isList) = (.asset, arity.isList)
    }
    return isList ? .list(element) : element
  }
}

extension FieldValue.Arity {
  /// Whether this is a list, empty or not.
  internal var isList: Bool {
    if case .list = self {
      return true
    }
    return false
  }
}
