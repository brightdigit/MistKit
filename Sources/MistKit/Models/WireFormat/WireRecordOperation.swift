//
//  WireRecordOperation.swift
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

/// One `records/modify` operation in CloudKit Web Services JSON:
/// `{"operationType": …, "record": {…}}`.
///
/// The record dictionary is written `recordName`, `recordType`,
/// `recordChangeTag`, `fields` (sorted by field name), then the sharing keys
/// MistKit sends for `cloudkit.share` records. Delete operations carry only
/// `recordName` and `recordChangeTag`; CloudKit needs nothing else to delete.
/// ``RecordOperation/clearedFields`` encode as `{"value": null}` and
/// ``RecordOperation/encryptedFields`` with `"isEncrypted": true`.
///
/// Decoding reads the operation type, record name, type, change tag and fields
/// (cleared and encrypted ones included). The sharing keys aren't decoded.
public struct WireRecordOperation: Codable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case operationType
    case record
  }

  private enum RecordKeys: String, CodingKey {
    case recordName
    case recordType
    case recordChangeTag
    case fields
    case createShortGUID
    case forRecord
    case publicPermission
    case participants
  }

  private struct FieldKey: CodingKey {
    let stringValue: String
    var intValue: Int? { nil }

    init(stringValue: String) {
      self.stringValue = stringValue
    }

    init?(intValue _: Int) {
      nil
    }
  }

  private struct EncryptedFlag: Decodable {
    let isEncrypted: Bool?
  }

  /// The operation.
  public var operation: RecordOperation
  /// When field dictionaries carry `type`.
  public var typeTagging: FieldTypeTagging

  /// Creates a wire operation.
  public init(_ operation: RecordOperation, typeTagging: FieldTypeTagging = .whenRequired) {
    self.operation = operation
    self.typeTagging = typeTagging
  }

  /// Decodes an operation.
  ///
  /// - Throws: `DecodingError` for an unknown `operationType` or malformed
  ///   JSON, or ``ConversionError`` for a field value that contradicts its type.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let wireType = try container.decode(
      Components.Schemas.RecordOperation.operationTypePayload.self,
      forKey: .operationType
    )
    let record = try container.nestedContainer(keyedBy: RecordKeys.self, forKey: .record)
    var fields: [String: FieldValue] = [:]
    var cleared: Set<String> = []
    var encrypted: Set<String> = []
    var tagging = FieldTypeTagging.whenRequired
    if record.contains(.fields) {
      let fieldContainer = try record.nestedContainer(keyedBy: FieldKey.self, forKey: .fields)
      for key in fieldContainer.allKeys {
        let field = try fieldContainer.decode(WireFieldValue.self, forKey: key)
        if field.typeTagging == .always {
          tagging = .always
        }
        if let value = field.value {
          fields[key.stringValue] = value
        } else {
          cleared.insert(key.stringValue)
        }
        if try fieldContainer.decode(EncryptedFlag.self, forKey: key).isEncrypted == true {
          encrypted.insert(key.stringValue)
        }
      }
    }
    self.init(
      RecordOperation(
        operationType: RecordOperation.OperationType(wireType),
        recordType: try record.decodeIfPresent(String.self, forKey: .recordType) ?? "",
        recordName: try record.decodeIfPresent(String.self, forKey: .recordName),
        fields: fields,
        clearedFields: cleared,
        encryptedFields: encrypted,
        recordChangeTag: try record.decodeIfPresent(String.self, forKey: .recordChangeTag)
      ),
      typeTagging: tagging
    )
  }

  /// Encodes the operation.
  ///
  /// - Throws: `EncodingError` when a number isn't finite.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(
      Components.Schemas.RecordOperation.operationTypePayload(operation.operationType),
      forKey: .operationType
    )
    var record = container.nestedContainer(keyedBy: RecordKeys.self, forKey: .record)
    try record.encodeIfPresent(operation.recordName, forKey: .recordName)
    guard !operation.operationType.isDelete else {
      try record.encodeIfPresent(operation.recordChangeTag, forKey: .recordChangeTag)
      return
    }
    try record.encode(operation.recordType, forKey: .recordType)
    try record.encodeIfPresent(operation.recordChangeTag, forKey: .recordChangeTag)
    try encodeFields(into: &record)
    try record.encodeIfPresent(operation.createShortGUID, forKey: .createShortGUID)
    try record.encodeIfPresent(
      operation.forRecord.map(Components.Schemas.ShareTargetReference.init(from:)),
      forKey: .forRecord
    )
    try record.encodeIfPresent(
      operation.publicPermission.map {
        Components.Schemas.RecordRequest.publicPermissionPayload(from: $0)
      },
      forKey: .publicPermission
    )
    try record.encodeIfPresent(
      operation.participants?.map(Components.Schemas.ShareParticipant.init(from:)),
      forKey: .participants
    )
  }

  private func encodeFields(
    into record: inout KeyedEncodingContainer<RecordKeys>
  ) throws {
    var fields = record.nestedContainer(keyedBy: FieldKey.self, forKey: .fields)
    let names = Set(operation.fields.keys).union(operation.clearedFields).sorted()
    for name in names {
      let field = WireFieldValue(operation.fields[name], typeTagging: typeTagging)
      try fields.encode(
        field.request(isEncrypted: operation.encryptedFields.contains(name)),
        forKey: FieldKey(stringValue: name)
      )
    }
  }
}

extension RecordOperation.OperationType {
  /// Whether this deletes the record.
  internal var isDelete: Bool {
    self == .delete || self == .forceDelete
  }

  // swiftlint:disable:next cyclomatic_complexity
  internal init(_ wire: Components.Schemas.RecordOperation.operationTypePayload) {
    switch wire {
    case .create: self = .create
    case .update: self = .update
    case .forceUpdate: self = .forceUpdate
    case .replace: self = .replace
    case .forceReplace: self = .forceReplace
    case .delete: self = .delete
    case .forceDelete: self = .forceDelete
    }
  }
}

extension Components.Schemas.RecordOperation.operationTypePayload {
  // swiftlint:disable:next cyclomatic_complexity
  internal init(_ operationType: RecordOperation.OperationType) {
    switch operationType {
    case .create: self = .create
    case .update: self = .update
    case .forceUpdate: self = .forceUpdate
    case .replace: self = .replace
    case .forceReplace: self = .forceReplace
    case .delete: self = .delete
    case .forceDelete: self = .forceDelete
    }
  }
}
