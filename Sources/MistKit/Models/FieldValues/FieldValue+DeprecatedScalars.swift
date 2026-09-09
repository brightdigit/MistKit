//
//  FieldValue+DeprecatedScalars.swift
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

public import Foundation

/// Deprecated scalar construction shims for the pre-``Arity`` call shape
/// (`.string("x")` → `.string(.value("x"))`). There is deliberately **no**
/// `.list([FieldValue])` polyfill — list call sites migrate to
/// `.string(.list(...))` (and peers) and break cleanly (issue #481).
extension FieldValue {
  /// Creates a string field. Prefer `.string(.value(...))`.
  @available(*, deprecated, message: "Use .string(.value(...))")
  public static func string(_ value: String) -> FieldValue {
    .string(.value(value))
  }

  /// Creates an int64 field. Prefer `.int64(.value(...))`.
  @available(*, deprecated, message: "Use .int64(.value(...))")
  public static func int64(_ value: Int) -> FieldValue {
    .int64(.value(value))
  }

  /// Creates a double field. Prefer `.double(.value(...))`.
  @available(*, deprecated, message: "Use .double(.value(...))")
  public static func double(_ value: Double) -> FieldValue {
    .double(.value(value))
  }

  /// Creates a bytes field. Prefer `.bytes(.value(...))`.
  @available(*, deprecated, message: "Use .bytes(.value(...))")
  public static func bytes(_ value: Data) -> FieldValue {
    .bytes(.value(value))
  }

  /// Creates a date field. Prefer `.date(.value(...))`.
  @available(*, deprecated, message: "Use .date(.value(...))")
  public static func date(_ value: Date) -> FieldValue {
    .date(.value(value))
  }

  /// Creates a location field. Prefer `.location(.value(...))`.
  @available(*, deprecated, message: "Use .location(.value(...))")
  public static func location(_ value: Location) -> FieldValue {
    .location(.value(value))
  }

  /// Creates a reference field. Prefer `.reference(.value(...))`.
  @available(*, deprecated, message: "Use .reference(.value(...))")
  public static func reference(_ value: Reference) -> FieldValue {
    .reference(.value(value))
  }

  /// Creates an asset field. Prefer `.asset(.value(...))`.
  @available(*, deprecated, message: "Use .asset(.value(...))")
  public static func asset(_ value: Asset) -> FieldValue {
    .asset(.value(value))
  }
}
