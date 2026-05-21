//
//  ConversionError.swift
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

/// A specific failure encountered while mapping a decoded CloudKit response
/// payload into a MistKit domain type.
///
/// CloudKit responses decode at the transport layer but can still carry shapes
/// MistKit can't faithfully represent — an unmappable field value, a record or
/// zone missing a required identifier, a negative timestamp, and so on. Rather
/// than silently dropping or masking such data, the conversion initializers
/// throw a typed `ConversionError` naming exactly what failed. At the
/// `CloudKitService` boundary it is wrapped into
/// ``CloudKitError/conversionFailed(_:)``.
public enum ConversionError: LocalizedError, Sendable, Equatable {
  /// A field value's structure matched no known `FieldValue` case.
  case unmappableFieldValue(fieldName: String, value: String, type: String?)
  /// A location field was missing its latitude and/or longitude.
  case locationMissingCoordinates(fieldName: String)
  /// A reference field was missing its `recordName`.
  case referenceMissingRecordName(fieldName: String)
  /// A list element matched no known `FieldValue` case.
  case unmappableListItem(fieldName: String, item: String)
  /// A nested-list element was not one of the supported basic types.
  case unmappableNestedListItem(fieldName: String, item: String)
  /// A record timestamp was negative.
  case negativeTimestamp(milliseconds: Double)
  /// A record response was missing `recordName` and/or `recordType`.
  case recordMissingIdentifier(recordName: String?, recordType: String?)
  /// A zone response was missing its `zoneID`.
  case zoneMissingID
  /// A zone response was missing its `zoneName`.
  case zoneMissingName
  /// A user response was missing its `userRecordName`.
  case userMissingRecordName

  /// A human-readable description of what failed during conversion.
  public var errorDescription: String? {
    self.message
  }

  /// The diagnostic message logged and trapped on by the conversion-failure
  /// reporter, and surfaced via ``errorDescription``.
  internal var message: String {
    switch self {
    case .unmappableFieldValue(let fieldName, let value, let type):
      return "Unmappable FieldValue for field '\(fieldName)' "
        + "(value: \(value), type: \(type ?? "nil"))"
    case .locationMissingCoordinates(let fieldName):
      return "Location field '\(fieldName)' missing latitude/longitude"
    case .referenceMissingRecordName(let fieldName):
      return "Reference field '\(fieldName)' missing recordName"
    case .unmappableListItem(let fieldName, let item):
      return "Unmappable list item for field '\(fieldName)' (\(item))"
    case .unmappableNestedListItem(let fieldName, let item):
      return "Unmappable nested list item for field '\(fieldName)' (\(item))"
    case .negativeTimestamp(let milliseconds):
      return "Invalid negative timestamp (\(milliseconds) ms)"
    case .recordMissingIdentifier(let recordName, let recordType):
      return "RecordResponse missing required identifier(s) "
        + "(recordName: \(recordName ?? "nil"), recordType: \(recordType ?? "nil"))"
    case .zoneMissingID:
      return "Zone entry missing zoneID"
    case .zoneMissingName:
      return "Zone entry missing zoneName"
    case .userMissingRecordName:
      return "UserResponse missing userRecordName"
    }
  }
}
