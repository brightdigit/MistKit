//
//  FieldValue+ListConvenience.swift
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

extension FieldValue {
  /// Extract an asset list if this is an `.asset(.list)` case.
  public var assetListValue: [Asset]? {
    if case .asset(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Flatten a homogeneous list back to `[FieldValue]` of `.value` elements.
  ///
  /// Prefer the typed `*ListValue` accessors. Kept for read-only consumers that
  /// previously matched `.list([FieldValue])`.
  @available(
    *,
    deprecated,
    message: "Use stringListValue, int64ListValue, or the matching *ListValue accessor"
  )
  public var listValue: [FieldValue]? {
    switch self {
    case .string(.list(let values)):
      return values.map { .string(.value($0)) }
    case .int64(.list(let values)):
      return values.map { .int64(.value($0)) }
    case .double(.list(let values)):
      return values.map { .double(.value($0)) }
    case .bytes(.list(let values)):
      return values.map { .bytes(.value($0)) }
    case .date(.list(let values)):
      return values.map { .date(.value($0)) }
    case .location(.list(let values)):
      return values.map { .location(.value($0)) }
    case .reference(.list(let values)):
      return values.map { .reference(.value($0)) }
    case .asset(.list(let values)):
      return values.map { .asset(.value($0)) }
    case .string(.value), .int64(.value), .double(.value), .bytes(.value),
      .date(.value), .location(.value), .reference(.value), .asset(.value):
      return nil
    }
  }
}
