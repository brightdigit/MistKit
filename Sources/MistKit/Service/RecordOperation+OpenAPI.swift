//
//  RecordOperation+OpenAPI.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Foundation

/// Internal conversion between public RecordOperation and OpenAPI types
extension RecordOperation {
  /// Mapping from RecordOperation.OperationType to OpenAPI operationTypePayload
  private static let operationTypeMapping: [RecordOperation.OperationType: Components.Schemas.RecordOperation.operationTypePayload] = [
    .create: .create,
    .update: .update,
    .forceUpdate: .forceUpdate,
    .replace: .replace,
    .forceReplace: .forceReplace,
    .delete: .delete,
    .forceDelete: .forceDelete
  ]

  /// Convert public RecordOperation to internal OpenAPI RecordOperation
  internal func toComponentsRecordOperation() -> Components.Schemas.RecordOperation {
    // Convert operation type using dictionary lookup
    guard let apiOperationType = Self.operationTypeMapping[operationType] else {
      fatalError("Unknown operation type: \(operationType)")
    }

    // Convert fields to OpenAPI FieldValue format
    let apiFields = fields.mapValues { fieldValue -> Components.Schemas.FieldValue in
      RecordFieldConverter.toComponentsFieldValue(fieldValue)
    }

    // Build the OpenAPI record operation
    return Components.Schemas.RecordOperation(
      operationType: apiOperationType,
      record: .init(
        recordName: recordName,
        recordType: recordType,
        recordChangeTag: recordChangeTag,
        fields: .init(additionalProperties: apiFields)
      )
    )
  }
}
