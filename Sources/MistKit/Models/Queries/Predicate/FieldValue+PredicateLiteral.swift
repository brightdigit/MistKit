//
//  FieldValue+PredicateLiteral.swift
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
  /// The value as a predicate literal; `nil` for assets, lists and non-finite
  /// numbers, which have none.
  internal var predicateLiteral: String? {
    switch self {
    case .string(.value(let string)):
      PredicateLiteral.quoted(string)
    case .int64(.value(let integer)):
      String(integer)
    case .double(.value(let double)):
      PredicateLiteral.number(double)
    case .date(.value(let date)):
      PredicateLiteral.date(date)
    case .reference(.value(let reference)):
      "REFERENCE(\(PredicateLiteral.quoted(reference.recordName)))"
    case .location(.value(let location)):
      PredicateLiteral.location(location)
    case .bytes(.value(let data)):
      "BYTES(\(PredicateLiteral.quoted(data.base64EncodedString())))"
    default:
      nil
    }
  }
}
