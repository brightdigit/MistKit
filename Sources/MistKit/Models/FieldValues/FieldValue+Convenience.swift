//
//  FieldValue+Convenience.swift
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

/// Convenience extensions for extracting typed values from FieldValue cases
extension FieldValue {
  /// Extract a String value if this is a `.string(.value)` case.
  ///
  /// - Returns: The string value, or nil if this is not a single-string field
  public var stringValue: String? {
    if case .string(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a string list if this is a `.string(.list)` case.
  public var stringListValue: [String]? {
    if case .string(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract an Int value if this is an `.int64(.value)` case.
  ///
  /// - Returns: The integer value, or nil if this is not a single-int64 field
  public var intValue: Int? {
    if case .int64(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract an int64 list if this is an `.int64(.list)` case.
  public var int64ListValue: [Int]? {
    if case .int64(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract a Double value if this is a `.double(.value)` case.
  ///
  /// - Returns: The double value, or nil if this is not a single-double field
  public var doubleValue: Double? {
    if case .double(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a double list if this is a `.double(.list)` case.
  public var doubleListValue: [Double]? {
    if case .double(.list(let values)) = self {
      return values
    }
    return nil
  }

  // swiftlint:disable discouraged_optional_boolean
  /// Extract a Bool value from `.int64(.value)` cases
  ///
  /// CloudKit represents booleans as INT64 where 0 is false and 1 is true.
  /// This method asserts that the value is either 0 or 1.
  ///
  /// - Returns: The boolean value, or nil if this is not an `.int64(.value)` case
  public var boolValue: Bool? {
    boolValue(assertionHandler: { condition, message in
      assert(condition, message)
    })
  }
  // swiftlint:enable discouraged_optional_boolean

  /// Extract a Date value if this is a `.date(.value)` case.
  ///
  /// - Returns: The date value, or nil if this is not a single-date field
  public var dateValue: Date? {
    if case .date(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a date list if this is a `.date(.list)` case.
  public var dateListValue: [Date]? {
    if case .date(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract base64-encoded bytes if this is a `.bytes(.value)` case.
  ///
  /// - Returns: The payload as a base64 string, or nil if this is not a single-bytes field
  public var bytesValue: String? {
    if case .bytes(.value(let value)) = self {
      return value.base64EncodedString()
    }
    return nil
  }

  /// Extract a bytes list (as base64 strings) if this is a `.bytes(.list)` case.
  public var bytesListValue: [Data]? {
    if case .bytes(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract the binary payload if this is a `.bytes(.value)` case.
  ///
  /// Matches `.bytes(.value)` only. An untagged CloudKit `BYTES` response is claimed by
  /// first-match-wins inference as `.string`, so `dataValue` returns `nil` for
  /// it; the base64 text remains available via ``stringValue``. This accessor
  /// does not attempt `Data(base64Encoded:)` on a `.string` payload: base64 has
  /// no false-positive signal, so ordinary strings such as `"Chen"` or `"test"`
  /// would decode as plausible-looking garbage.
  ///
  /// - Returns: The `Data` payload, or nil if this is not a single-bytes field
  public var dataValue: Data? {
    if case .bytes(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a Location value if this is a `.location(.value)` case.
  ///
  /// - Returns: The location value, or nil if this is not a single-location field
  public var locationValue: Location? {
    if case .location(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a location list if this is a `.location(.list)` case.
  public var locationListValue: [Location]? {
    if case .location(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract a Reference value if this is a `.reference(.value)` case.
  ///
  /// - Returns: The reference value, or nil if this is not a single-reference field
  public var referenceValue: Reference? {
    if case .reference(.value(let value)) = self {
      return value
    }
    return nil
  }

  /// Extract a reference list if this is a `.reference(.list)` case.
  public var referenceListValue: [Reference]? {
    if case .reference(.list(let values)) = self {
      return values
    }
    return nil
  }

  /// Extract an Asset value if this is an `.asset(.value)` case.
  ///
  /// - Returns: The asset value, or nil if this is not a single-asset field
  public var assetValue: Asset? {
    if case .asset(.value(let value)) = self {
      return value
    }
    return nil
  }

  // swiftlint:disable discouraged_optional_boolean
  /// Internal method to extract Bool value with custom assertion handler
  ///
  /// - Parameter assertionHandler: Custom assertion handler for testing, defaults to system assert
  /// - Returns: The boolean value, or nil if this is not an `.int64(.value)` case
  internal func boolValue(
    assertionHandler: (_ condition: Bool, _ message: String) -> Void = { condition, message in
      assert(condition, message)
    }
  ) -> Bool? {
    if case .int64(.value(let value)) = self {
      assertionHandler(
        value == 0 || value == 1,
        "Boolean int64 value must be 0 or 1, got \(value)"
      )
      return value != 0
    }
    return nil
  }
  // swiftlint:enable discouraged_optional_boolean
}
