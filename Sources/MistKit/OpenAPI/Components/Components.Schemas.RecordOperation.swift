//
//  Components.Schemas.RecordOperation.swift
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

/// Extension to convert MistKit RecordOperation to OpenAPI Components.Schemas.RecordOperation
extension Components.Schemas.RecordOperation {
  /// Mapping from RecordOperation.OperationType to OpenAPI operationTypePayload
  private static let operationTypeMapping:
    [RecordOperation.OperationType: Components.Schemas.RecordOperation.operationTypePayload] = [
      .create: .create,
      .update: .update,
      .forceUpdate: .forceUpdate,
      .replace: .replace,
      .forceReplace: .forceReplace,
      .delete: .delete,
      .forceDelete: .forceDelete,
    ]

  /// Initialize from MistKit RecordOperation
  internal init(from recordOperation: RecordOperation) throws(CloudKitError) {
    // Convert operation type using dictionary lookup
    guard let apiOperationType = Self.operationTypeMapping[recordOperation.operationType] else {
      throw CloudKitError.unsupportedOperationType("\(recordOperation.operationType)")
    }

    // Convert fields to OpenAPI FieldValueRequest format (for requests),
    // tagging encrypted field names with isEncrypted: true.
    var apiFields: [String: Components.Schemas.FieldValueRequest] = [:]
    apiFields.reserveCapacity(recordOperation.fields.count)
    for (fieldName, fieldValue) in recordOperation.fields {
      var request = Components.Schemas.FieldValueRequest(from: fieldValue)
      if recordOperation.encryptedFields.contains(fieldName) {
        // Verified live (2026-09-14): an encrypted field whose `type` is left for
        // CloudKit to infer is read as ENCRYPTED_BYTES and rejected with
        // BAD_REQUEST "invalid attempt to set value type ENCRYPTED_BYTES for
        // field … defined to be: ENCRYPTED_STRING". Apple's own example tags
        // every encrypted field explicitly, so do the same for all of them.
        request.isEncrypted = true
        if request._type == nil {
          request._type = Self.explicitType(for: fieldValue)
        }
      }
      apiFields[fieldName] = request
    }

    // Build the OpenAPI record operation
    self.init(
      operationType: apiOperationType,
      record: .init(
        recordName: recordOperation.recordName,
        recordType: recordOperation.recordType,
        recordChangeTag: recordOperation.recordChangeTag,
        fields: .init(additionalProperties: apiFields),
        createShortGUID: recordOperation.createShortGUID,
        forRecord: recordOperation.forRecord.map(
          Components.Schemas.ShareTargetReference.init(from:)
        ),
        publicPermission: recordOperation.publicPermission.map {
          Components.Schemas.RecordRequest.publicPermissionPayload(from: $0)
        },
        participants: recordOperation.participants?.map(
          Components.Schemas.ShareParticipant.init(from:)
        )
      )
    )
  }

  // The wire `type` for an encrypted value the request conversion leaves untagged.
  //
  // Since #481 every list arity is tagged `*_LIST` by `FieldValueRequest.init(from:)`,
  // and `.double`/`.bytes`/`.date` scalars already carry DOUBLE/BYTES/TIMESTAMP — none
  // of those reach here, because the caller only consults this when `_type == nil`.
  // In practice that leaves `.string`, `.int64` and `.location` scalars;
  // `.reference`/`.asset` are rejected upstream by `validateEncryptedFields(for:)`.
  // The `switch` is `default`-free on purpose, so a new `FieldValue` case breaks the
  // build here rather than silently sending an untagged encrypted field.
  // swiftlint:disable:next cyclomatic_complexity
  private static func explicitType(
    for fieldValue: FieldValue
  ) -> Components.Schemas.FieldValueRequest._typePayload? {
    switch fieldValue {
    case .string(.value):
      return .STRING
    case .int64(.value):
      return .INT64
    case .double(.value):
      return .DOUBLE
    case .bytes(.value):
      return .BYTES
    case .date(.value):
      return .TIMESTAMP
    case .location(.value):
      return .LOCATION
    case .reference(.value):
      return .REFERENCE
    case .asset(.value):
      return .ASSET
    case .string(.list), .int64(.list), .double(.list), .bytes(.list),
      .date(.list), .location(.list), .reference(.list), .asset(.list):
      // Already tagged `*_LIST` by the request conversion.
      return nil
    }
  }
}
