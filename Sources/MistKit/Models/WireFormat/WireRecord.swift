//
//  WireRecord.swift
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

/// A whole record in CloudKit Web Services JSON, as a query or lookup
/// response has it: `{"recordName": …, "recordType": …, "recordChangeTag": …,
/// "zoneID": {…}, "fields": {…}, "created": {…}, "modified": {…}}`.
///
/// Fields are ``WireFieldValue``s, written sorted by name; by default each
/// carries its `type`, as a response does. ``clearedFields`` are written
/// `{"value": null}` and ``encryptedFields`` with `"isEncrypted": true`.
/// `created` and `modified` hold whole milliseconds since 1970, `deleted` is
/// written only for a tombstone, and every other `nil` key is left out.
///
/// Decoding reads the same keys. A field without a `type` is typed by the
/// decoder's `CodingUserInfoKey.cloudKitFieldTypes`, then by its JSON shape.
///
/// ```swift
/// let json = try JSONEncoder.cloudKitReadable.encode(records.map { WireRecord($0) })
/// let back = try JSONDecoder().decode([WireRecord].self, from: json)
///   .map { try RecordInfo($0) }
/// ```
public struct WireRecord: Codable, Hashable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case recordName
    case recordType
    case recordChangeTag
    case zoneID
    case fields
    case created
    case modified
    case deleted
  }

  /// The record name; `nil` for a record CloudKit hasn't named yet.
  public var recordName: String?
  /// The record type; `nil` for a tombstone.
  public var recordType: String?
  /// The change tag the record was read at.
  public var recordChangeTag: String?
  /// The record's zone; `nil` when the JSON didn't say.
  public var zoneID: ZoneID?
  /// The set fields.
  public var fields: [String: FieldValue]
  /// Field names written `{"value": null}`.
  ///
  /// A name in both ``fields`` and `clearedFields` is written with its value.
  public var clearedFields: Set<String>
  /// Field names written with `"isEncrypted": true`.
  public var encryptedFields: Set<String>
  /// When and by whom the record was created.
  public var created: RecordTimestamp?
  /// When and by whom the record was last modified.
  public var modified: RecordTimestamp?
  /// Whether this is a tombstone.
  public var deleted: Bool
  /// When field dictionaries carry `type`. Decoding sets
  /// ``FieldTypeTagging/always`` when any field had a `type`.
  public var typeTagging: FieldTypeTagging

  /// Creates a wire record.
  public init(
    recordName: String?,
    recordType: String?,
    recordChangeTag: String? = nil,
    zoneID: ZoneID? = nil,
    fields: [String: FieldValue] = [:],
    clearedFields: Set<String> = [],
    encryptedFields: Set<String> = [],
    created: RecordTimestamp? = nil,
    modified: RecordTimestamp? = nil,
    deleted: Bool = false,
    typeTagging: FieldTypeTagging = .always
  ) {
    self.recordName = recordName
    self.recordType = recordType
    self.recordChangeTag = recordChangeTag
    self.zoneID = zoneID
    self.fields = fields
    self.clearedFields = clearedFields
    self.encryptedFields = encryptedFields
    self.created = created
    self.modified = modified
    self.deleted = deleted
    self.typeTagging = typeTagging
  }

  /// The wire form of a record.
  ///
  /// - Parameters:
  ///   - record: The record.
  ///   - typeTagging: When field dictionaries carry `type`; every field by
  ///     default, as a response has them.
  public init(_ record: RecordInfo, typeTagging: FieldTypeTagging = .always) {
    self.init(
      recordName: record.recordName,
      recordType: record.recordType,
      recordChangeTag: record.recordChangeTag,
      zoneID: record.zoneID,
      fields: record.fields,
      encryptedFields: record.encryptedFields,
      created: record.created,
      modified: record.modified,
      deleted: record.deleted,
      typeTagging: typeTagging
    )
  }

  /// Decodes a record dictionary.
  ///
  /// - Throws: `DecodingError` for malformed JSON, and
  ///   `DecodingError.dataCorrupted` with a ``ConversionError`` as its
  ///   `underlyingError` for a field value that contradicts its type (at the
  ///   field), an unknown `zoneType` or a negative timestamp (at the record).
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let fields = try WireFields(from: container, forKey: .fields)
    let zoneID = try container.decodeIfPresent(Components.Schemas.ZoneID.self, forKey: .zoneID)
    let created = try container.decodeIfPresent(
      Components.Schemas.RecordTimestamp.self,
      forKey: .created
    )
    let modified = try container.decodeIfPresent(
      Components.Schemas.RecordTimestamp.self,
      forKey: .modified
    )
    let converted = try ConversionFailureReporter.decodingWithoutTrapping(
      at: container.codingPath
    ) {
      (
        zoneID: try zoneID.map { schema throws(ConversionError) in try ZoneID(from: schema) },
        created: try created.map { stamp throws(ConversionError) in
          try RecordTimestamp(from: stamp)
        },
        modified: try modified.map { stamp throws(ConversionError) in
          try RecordTimestamp(from: stamp)
        }
      )
    }
    self.init(
      recordName: try container.decodeIfPresent(String.self, forKey: .recordName),
      recordType: try container.decodeIfPresent(String.self, forKey: .recordType),
      recordChangeTag: try container.decodeIfPresent(String.self, forKey: .recordChangeTag),
      zoneID: converted.zoneID,
      fields: fields.values,
      clearedFields: fields.cleared,
      encryptedFields: fields.encrypted,
      created: converted.created,
      modified: converted.modified,
      deleted: try container.decodeIfPresent(Bool.self, forKey: .deleted) ?? false,
      typeTagging: fields.typeTagging
    )
  }

  /// Encodes the record dictionary.
  ///
  /// - Throws: `EncodingError` when a number isn't finite.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encodeIfPresent(recordName, forKey: .recordName)
    try container.encodeIfPresent(recordType, forKey: .recordType)
    try container.encodeIfPresent(recordChangeTag, forKey: .recordChangeTag)
    try container.encodeIfPresent(
      zoneID.map(Components.Schemas.ZoneID.init(from:)),
      forKey: .zoneID
    )
    try WireFields(
      values: fields,
      cleared: clearedFields,
      encrypted: encryptedFields,
      typeTagging: typeTagging
    )
    .encode(to: &container, forKey: .fields)
    try container.encodeIfPresent(created.map(WireRecordTimestamp.init), forKey: .created)
    try container.encodeIfPresent(modified.map(WireRecordTimestamp.init), forKey: .modified)
    if deleted {
      try container.encode(true, forKey: .deleted)
    }
  }
}
