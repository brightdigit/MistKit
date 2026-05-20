//
//  RecordInfo.swift
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

/// Record information from CloudKit.
///
/// A `RecordInfo` always represents a successfully-returned record: it carries a
/// non-optional `recordName` and `recordType`. Per-record failures from
/// `modifyRecords` / `lookupRecords` are surfaced separately as
/// ``RecordResult/failure(_:)`` (a ``RecordError``) and never become a
/// `RecordInfo`. A response record missing its identifiers is treated as a
/// conversion failure (logged, asserted in DEBUG, and thrown).
public struct RecordInfo: Codable, Sendable {
  /// The record name
  public let recordName: String
  /// The record type
  public let recordType: String
  /// The record change tag for optimistic locking
  public let recordChangeTag: String?
  /// The record fields
  public let fields: [String: FieldValue]
  /// Information about when the record was created
  public let created: RecordTimestamp?
  /// Information about when the record was last modified
  public let modified: RecordTimestamp?
  /// When `true`, this is a tombstone entry from `fetchRecordChanges()` —
  /// the record was deleted and should be removed from local storage.
  public let deleted: Bool

  internal init(from record: Components.Schemas.RecordResponse) throws {
    guard let recordName = record.recordName, let recordType = record.recordType else {
      try CloudKitError.reportConversionFailure(
        "RecordResponse missing required identifier(s) "
          + "(recordName: \(String(describing: record.recordName)), "
          + "recordType: \(String(describing: record.recordType)))"
      )
    }
    self.recordName = recordName
    self.recordType = recordType
    self.recordChangeTag = record.recordChangeTag
    self.created = try record.created.map(RecordTimestamp.init(from:))
    self.modified = try record.modified.map(RecordTimestamp.init(from:))
    self.deleted = record.deleted ?? false

    // Convert fields to FieldValue representation
    var convertedFields: [String: FieldValue] = [:]

    if let fieldsPayload = record.fields {
      for (fieldName, fieldData) in fieldsPayload.additionalProperties {
        convertedFields[fieldName] = try FieldValue(fieldData, fieldName: fieldName)
      }
    }

    self.fields = convertedFields
  }

  /// Public initializer for creating RecordInfo instances
  ///
  /// This initializer is primarily intended for testing and cases where you need to
  /// construct RecordInfo manually rather than receiving it from CloudKit responses.
  ///
  /// - Parameters:
  ///   - recordName: The unique record name
  ///   - recordType: The CloudKit record type
  ///   - recordChangeTag: Optional change tag for optimistic locking
  ///   - fields: Dictionary of field names to their values
  ///   - created: Optional timestamp when the record was created
  ///   - modified: Optional timestamp when the record was last modified
  ///   - deleted: Whether the record has been deleted
  public init(
    recordName: String,
    recordType: String,
    recordChangeTag: String? = nil,
    fields: [String: FieldValue],
    created: RecordTimestamp? = nil,
    modified: RecordTimestamp? = nil,
    deleted: Bool = false
  ) {
    self.recordName = recordName
    self.recordType = recordType
    self.recordChangeTag = recordChangeTag
    self.fields = fields
    self.created = created
    self.modified = modified
    self.deleted = deleted
  }
}
