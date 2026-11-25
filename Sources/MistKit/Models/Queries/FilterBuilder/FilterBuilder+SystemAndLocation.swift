//
//  FilterBuilder+SystemAndLocation.swift
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
internal import MistKitOpenAPI

extension FilterBuilder {
  /// The system field CloudKit Web Services filters record names on.
  internal static let recordIDFieldName = "___recordID"

  // MARK: Location Filters

  /// Creates a NEAR filter.
  /// - Parameters:
  ///   - field: The `LOCATION` field to filter on
  ///   - location: The center of the circle
  ///   - distance: The radius, in meters
  /// - Returns: A configured Filter
  internal static func near(
    _ field: String,
    _ location: Location,
    distance: Double
  ) -> Components.Schemas.Filter {
    .init(
      comparator: .NEAR,
      fieldName: field,
      fieldValue: .init(from: .location(.value(location))),
      distance: distance
    )
  }

  // MARK: Record Name Filters

  /// Creates an EQUALS or NOT_EQUALS filter on `___recordID`.
  ///
  /// CloudKit matches record names through the `___recordID` system field,
  /// whose value is a `REFERENCE` to the record.
  internal static func recordName(
    _ recordName: String,
    comparator: Components.Schemas.Filter.comparatorPayload
  ) -> Components.Schemas.Filter {
    .init(
      comparator: comparator,
      fieldName: recordIDFieldName,
      fieldValue: .init(from: .reference(.value(Reference(recordName: recordName))))
    )
  }
}
