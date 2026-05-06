//
//  ModifyOperationInput.swift
//  MistDemo
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
public import MistKit

/// One operation parsed from the modify ops JSON payload.
public struct ModifyOperationInput: Codable, Sendable {
  private enum CodingKeys: String, CodingKey {
    case operation = "op"
    case recordType
    case recordName
    case fields
    case recordChangeTag
  }

  /// The operation kind (create, update, or delete).
  public let operation: ModifyOperationKind
  /// The CloudKit record type.
  public let recordType: String
  /// The optional record name.
  public let recordName: String?
  /// The optional fields to set.
  public let fields: FieldsInput?
  /// The optional record change tag for conflict detection.
  public let recordChangeTag: String?

  /// Creates a new instance.
  public init(
    operation: ModifyOperationKind,
    recordType: String,
    recordName: String? = nil,
    fields: FieldsInput? = nil,
    recordChangeTag: String? = nil
  ) {
    self.operation = operation
    self.recordType = recordType
    self.recordName = recordName
    self.fields = fields
    self.recordChangeTag = recordChangeTag
  }

  /// Convert this operation input into a MistKit RecordOperation.
  public func toRecordOperation(index: Int) throws -> RecordOperation {
    let cloudKitFields: [String: FieldValue]
    if let fields {
      let domainFields = try fields.toFields()
      cloudKitFields = try domainFields.toCloudKitFields()
    } else {
      cloudKitFields = [:]
    }

    switch operation {
    case .create:
      return RecordOperation.create(
        recordType: recordType,
        recordName: recordName,
        fields: cloudKitFields
      )
    case .update:
      guard let recordName else {
        throw ModifyError.missingRecordName(
          opIndex: index,
          operation: operation.rawValue
        )
      }
      return RecordOperation.update(
        recordType: recordType,
        recordName: recordName,
        fields: cloudKitFields,
        recordChangeTag: recordChangeTag
      )
    case .delete:
      guard let recordName else {
        throw ModifyError.missingRecordName(
          opIndex: index,
          operation: operation.rawValue
        )
      }
      return RecordOperation.delete(
        recordType: recordType,
        recordName: recordName,
        recordChangeTag: recordChangeTag
      )
    }
  }
}
