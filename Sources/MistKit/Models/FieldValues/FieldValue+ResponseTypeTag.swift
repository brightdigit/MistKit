//
//  FieldValue+ResponseTypeTag.swift
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

internal import MistKitOpenAPI

/// Classification of an explicit CloudKit response `type` tag.
extension FieldValue {
  /// A declared `FieldValueResponse` `type`, grouped by the value category it demands.
  ///
  /// Every conversion decision keyed on a response `type` routes through ``init(_:)`` — the
  /// single, total, `default`-free mapping from the generated `_typePayload`. Adding a tag to
  /// the OpenAPI spec therefore breaks the build here until the new tag is classified, rather
  /// than silently falling into a `default` branch, which is what keeps the response
  /// conversions exhaustive at compile time.
  internal enum ResponseTypeTag: Hashable, Sendable {
    /// A tag that requires a numeric value (`TIMESTAMP`, `DOUBLE`, `INT64`).
    case numeric(NumericScalarTag)
    /// A tag that requires a string-backed value (`BYTES`, `STRING`).
    case text(TextScalarTag)
    /// A tag that requires a structured value (`REFERENCE`, `ASSET`/`ASSETID`, `LOCATION`,
    /// `LIST`).
    case complex(ExpectedComplexValue)

    // Classify a declared response `type`.
    //
    // `ASSETID` shares `AssetValue` — and therefore the `.asset` classification — with
    // `ASSET`; there is no distinct domain case for it.
    // swiftlint:disable:next cyclomatic_complexity
    internal init(_ fieldType: Components.Schemas.FieldValueResponse._typePayload) {
      switch fieldType {
      case .TIMESTAMP: self = .numeric(.timestamp)
      case .DOUBLE: self = .numeric(.double)
      case .INT64: self = .numeric(.int64)
      case .BYTES: self = .text(.bytes)
      case .STRING: self = .text(.string)
      case .REFERENCE: self = .complex(.reference)
      case .ASSET, .ASSETID: self = .complex(.asset)
      case .LOCATION: self = .complex(.location)
      case .LIST: self = .complex(.list)
      }
    }
  }

  /// A declared scalar `type` whose value must be numeric.
  internal enum NumericScalarTag: Hashable, Sendable {
    case timestamp
    case double
    case int64
  }

  /// A declared scalar `type` whose value must be string-backed.
  internal enum TextScalarTag: Hashable, Sendable {
    case bytes
    case string
  }

  /// The decoded `value` case a complex/list `FieldValueResponse` `type` tag requires (#376).
  internal enum ExpectedComplexValue: Hashable, Sendable {
    case reference
    case asset
    case location
    case list

    /// Whether `value`'s decoded `oneOf` case satisfies this declared complex/list tag.
    internal func matches(
      _ value: Components.Schemas.FieldValueResponse.valuePayload
    ) -> Bool {
      switch (self, value) {
      case (.reference, .ReferenceValue), (.asset, .AssetValue),
        (.location, .LocationValue), (.list, .ListValue):
        return true
      default:
        return false
      }
    }
  }
}
