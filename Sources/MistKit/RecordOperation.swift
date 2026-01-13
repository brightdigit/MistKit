//
//  RecordOperation.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation

/// Represents a CloudKit record operation (create, update, delete, etc.)
public struct RecordOperation: Sendable {
  /// The type of operation to perform
  public enum OperationType: Sendable {
    /// Create a new record
    case create
    /// Update an existing record
    case update
    /// Update an existing record, overwriting any conflicts
    case forceUpdate
    /// Replace an existing record
    case replace
    /// Replace an existing record, overwriting any conflicts
    case forceReplace
    /// Delete an existing record
    case delete
    /// Delete an existing record, overwriting any conflicts
    case forceDelete
  }

  /// The type of operation to perform
  public let operationType: OperationType
  /// The record type (e.g., "RestoreImage", "XcodeVersion")
  public let recordType: String
  /// The unique record name (optional for creates - CloudKit will generate one if not provided)
  public let recordName: String?
  /// The record fields as FieldValue types
  public let fields: [String: FieldValue]
  /// Optional record change tag for optimistic locking
  public let recordChangeTag: String?

  /// Initialize a record operation
  public init(
    operationType: OperationType,
    recordType: String,
    recordName: String?,
    fields: [String: FieldValue] = [:],
    recordChangeTag: String? = nil
  ) {
    self.operationType = operationType
    self.recordType = recordType
    self.recordName = recordName
    self.fields = fields
    self.recordChangeTag = recordChangeTag
  }

  /// Convenience initializer for creating a new record
  public static func create(
    recordType: String,
    recordName: String? = nil,
    fields: [String: FieldValue]
  ) -> RecordOperation {
    RecordOperation(
      operationType: .create,
      recordType: recordType,
      recordName: recordName,
      fields: fields
    )
  }

  /// Convenience initializer for updating an existing record
  public static func update(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String?
  ) -> RecordOperation {
    RecordOperation(
      operationType: .update,
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag
    )
  }

  /// Convenience initializer for deleting a record
  public static func delete(
    recordType: String,
    recordName: String,
    recordChangeTag: String? = nil
  ) -> RecordOperation {
    RecordOperation(
      operationType: .delete,
      recordType: recordType,
      recordName: recordName,
      fields: [:],
      recordChangeTag: recordChangeTag
    )
  }
}
