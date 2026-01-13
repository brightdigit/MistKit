//
//  FieldValue+Convenience.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import Foundation

/// Convenience extensions for extracting typed values from FieldValue cases
extension FieldValue {
  /// Extract a String value if this is a .string case
  ///
  /// - Returns: The string value, or nil if this is not a .string case
  public var stringValue: String? {
    if case .string(let value) = self {
      return value
    }
    return nil
  }

  /// Extract an Int value if this is an .int64 case
  ///
  /// - Returns: The integer value, or nil if this is not an .int64 case
  public var intValue: Int? {
    if case .int64(let value) = self {
      return value
    }
    return nil
  }

  /// Extract a Double value if this is a .double case
  ///
  /// - Returns: The double value, or nil if this is not a .double case
  public var doubleValue: Double? {
    if case .double(let value) = self {
      return value
    }
    return nil
  }

  /// Internal method to extract Bool value with custom assertion handler
  ///
  /// - Parameter assertionHandler: Custom assertion handler for testing, defaults to system assert
  /// - Returns: The boolean value, or nil if this is not an .int64 case
  internal func boolValue(
    assertionHandler: (_ condition: Bool, _ message: String) -> Void = { condition, message in
      assert(condition, message)
    }
  ) -> Bool? {
    if case .int64(let value) = self {
      assertionHandler(
        value == 0 || value == 1,
        "Boolean int64 value must be 0 or 1, got \(value)"
      )
      return value != 0
    }
    return nil
  }

  /// Extract a Bool value from .int64 cases
  ///
  /// CloudKit represents booleans as INT64 where 0 is false and 1 is true.
  /// This method asserts that the value is either 0 or 1.
  ///
  /// - Returns: The boolean value, or nil if this is not an .int64 case
  public var boolValue: Bool? {
    boolValue(assertionHandler: { condition, message in
      assert(condition, message)
    })
  }

  /// Extract a Date value if this is a .date case
  ///
  /// - Returns: The date value, or nil if this is not a .date case
  public var dateValue: Date? {
    if case .date(let value) = self {
      return value
    }
    return nil
  }

  /// Extract base64-encoded bytes if this is a .bytes case
  ///
  /// - Returns: The base64 string, or nil if this is not a .bytes case
  public var bytesValue: String? {
    if case .bytes(let value) = self {
      return value
    }
    return nil
  }

  /// Extract a Location value if this is a .location case
  ///
  /// - Returns: The location value, or nil if this is not a .location case
  public var locationValue: Location? {
    if case .location(let value) = self {
      return value
    }
    return nil
  }

  /// Extract a Reference value if this is a .reference case
  ///
  /// - Returns: The reference value, or nil if this is not a .reference case
  public var referenceValue: Reference? {
    if case .reference(let value) = self {
      return value
    }
    return nil
  }

  /// Extract an Asset value if this is an .asset case
  ///
  /// - Returns: The asset value, or nil if this is not an .asset case
  public var assetValue: Asset? {
    if case .asset(let value) = self {
      return value
    }
    return nil
  }

  /// Extract a list of FieldValues if this is a .list case
  ///
  /// - Returns: The array of field values, or nil if this is not a .list case
  public var listValue: [FieldValue]? {
    if case .list(let value) = self {
      return value
    }
    return nil
  }
}
