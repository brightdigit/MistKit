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
  /// A response declared a scalar `type` that the field's value cannot satisfy
  /// (e.g. a `TIMESTAMP` tag over a string value, or a `BYTES` tag over a string
  /// that is not valid base64). Such a response is internally inconsistent and
  /// cannot be faithfully represented.
  case typeValueMismatch(fieldName: String, declaredType: String, value: String)
  /// A list element matched no known `FieldValue` case.
  case unmappableListItem(fieldName: String, item: String)
  /// A nested-list element was not one of the supported basic types.
  case unmappableNestedListItem(fieldName: String, item: String)
  /// A record timestamp was negative.
  case negativeTimestamp(milliseconds: Double)
  /// A record response was missing its `recordName`.
  ///
  /// `recordType` is intentionally *not* required: CloudKit's Record Dictionary
  /// only guarantees `recordName` in a response, and omits `recordType` for
  /// tombstones (deleted records) and other typeless results.
  case recordMissingRecordName
  /// A zone response was missing its `zoneID`.
  case zoneMissingID
  /// A zone response was missing its `zoneName`.
  case zoneMissingName
  /// A zone response carried an unrecognized `zoneType` wire value.
  case unrecognizedZoneType(String)
  /// A user response was missing its `userRecordName`.
  case userMissingRecordName
  /// A subscription response was missing its `subscriptionID`.
  case subscriptionMissingID
  /// A subscription response was missing its `subscriptionType`.
  case subscriptionMissingType
  /// A `query` subscription response was missing or had an empty
  /// `firesOn` array — a query subscription with no fire events would
  /// never trigger and is invalid by construction.
  case subscriptionQueryMissingFiresOn
  /// A token response was missing or malformed a required field
  /// (`apnsEnvironment`/`apnsToken`/`webcourierURL`).
  case tokenMissingField(fieldName: String)
  /// A `cloudkit.share` create response was missing its `shortGUID`.
  case shareMissingShortGUID
  /// A resolve/accept result was missing its `shortGUID`.
  case shareResultMissingShortGUID
  /// A `cloudkit.share` record was present but missing required share keys
  /// (`shortGUID`, `publicPermission`, `owner`, `currentUserParticipant`, or
  /// a convertible `participants` entry).
  case shareIncomplete
  /// A `potentialMatchList` entry was missing its `participantId`.
  case sharePotentialMatchMissingParticipantId

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
    case .typeValueMismatch(let fieldName, let declaredType, let value):
      return "Field '\(fieldName)' declared type \(declaredType) "
        + "but its value is incompatible (\(value))"
    case .unmappableListItem(let fieldName, let item):
      return "Unmappable list item for field '\(fieldName)' (\(item))"
    case .unmappableNestedListItem(let fieldName, let item):
      return "Unmappable nested list item for field '\(fieldName)' (\(item))"
    case .negativeTimestamp(let milliseconds):
      return "Invalid negative timestamp (\(milliseconds) ms)"
    case .recordMissingRecordName:
      return "RecordResponse missing required recordName"
    case .zoneMissingID:
      return "Zone entry missing zoneID"
    case .zoneMissingName:
      return "Zone entry missing zoneName"
    case .unrecognizedZoneType(let wireValue):
      return "Zone entry has unrecognized zoneType '\(wireValue)'"
    case .userMissingRecordName:
      return "UserResponse missing userRecordName"
    case .subscriptionMissingID:
      return "Subscription entry missing subscriptionID"
    case .subscriptionMissingType:
      return "Subscription entry missing subscriptionType"
    case .subscriptionQueryMissingFiresOn:
      return "Query subscription missing or empty firesOn — a query "
        + "subscription must declare at least one of [create, update, delete]"
    case .tokenMissingField(let fieldName):
      return "TokenResponse missing required field '\(fieldName)'"
    case .shareMissingShortGUID:
      return "cloudkit.share create response missing required shortGUID"
    case .shareResultMissingShortGUID:
      return "ShortGUIDResult missing required shortGUID"
    case .shareIncomplete:
      return "cloudkit.share record missing required share keys "
        + "(shortGUID, publicPermission, owner, currentUserParticipant, "
        + "or convertible participants)"
    case .sharePotentialMatchMissingParticipantId:
      return "potentialMatchList entry missing required participantId"
    }
  }
}
