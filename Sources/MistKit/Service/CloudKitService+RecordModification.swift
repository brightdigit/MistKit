//
//  CloudKitService+RecordModification.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

/// Public record modification operations
@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Create a new record
  /// - Parameters:
  ///   - recordType: The type of record to create
  ///   - fields: The fields for the new record
  /// - Returns: The created record information
  @available(
    *, deprecated,
    message:
      "Use createRecord(recordType:recordName:fields:) in CloudKitService+WriteOperations instead. Pass nil for recordName to auto-generate UUID."
  )
  public func createRecord(
    recordType: String,
    fields: [String: FieldValue]
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = Components.Schemas.RecordOperation(
      operationType: .create,
      record: .init(
        recordType: recordType,
        fields: convertFieldsToComponents(fields)
      )
    )

    let results = try await modifyRecords(operations: [operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Update an existing record
  /// - Parameters:
  ///   - recordName: The name of the record to update
  ///   - recordType: The type of the record
  ///   - fields: The updated fields
  /// - Returns: The updated record information
  @available(
    *, deprecated, renamed: "updateRecord(recordType:recordName:fields:recordChangeTag:)",
    message: "Use the version in CloudKitService+WriteOperations instead"
  )
  public func updateRecord(
    recordName: String,
    recordType: String,
    fields: [String: FieldValue]
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = Components.Schemas.RecordOperation(
      operationType: .update,
      record: .init(
        recordName: recordName,
        recordType: recordType,
        fields: convertFieldsToComponents(fields)
      )
    )

    let results = try await modifyRecords(operations: [operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Delete a record
  /// - Parameters:
  ///   - recordName: The name of the record to delete
  ///   - recordType: The type of the record
  /// - Returns: The deleted record information
  @available(
    *, deprecated, renamed: "deleteRecord(recordType:recordName:recordChangeTag:)",
    message: "Use the version in CloudKitService+WriteOperations instead"
  )
  public func deleteRecord(
    recordName: String,
    recordType: String
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = Components.Schemas.RecordOperation(
      operationType: .forceDelete,
      record: .init(
        recordName: recordName,
        recordType: recordType
      )
    )

    let results = try await modifyRecords(operations: [operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Create multiple records in a single operation
  /// - Parameters:
  ///   - records: Array of tuples containing record type and fields
  ///   - atomic: Whether the operation should be atomic (default: false)
  /// - Returns: Array of created record information
  @available(
    *, deprecated,
    message:
      "Use modifyRecords(_:) with RecordOperation.create in CloudKitService+WriteOperations instead"
  )
  public func createRecords(
    _ records: [(recordType: String, fields: [String: FieldValue])],
    atomic: Bool = false
  ) async throws(CloudKitError) -> [RecordInfo] {
    let operations = records.map { recordType, fields in
      Components.Schemas.RecordOperation(
        operationType: .create,
        record: .init(
          recordType: recordType,
          fields: convertFieldsToComponents(fields)
        )
      )
    }

    return try await modifyRecords(operations: operations, atomic: atomic)
  }

  /// Delete multiple records in a single operation
  /// - Parameters:
  ///   - records: Array of tuples containing record name and type
  ///   - atomic: Whether the operation should be atomic (default: false)
  /// - Returns: Array of deleted record information
  @available(
    *, deprecated,
    message:
      "Use modifyRecords(_:) with RecordOperation.delete in CloudKitService+WriteOperations instead"
  )
  public func deleteRecords(
    _ records: [(recordName: String, recordType: String)],
    atomic: Bool = false
  ) async throws(CloudKitError) -> [RecordInfo] {
    let operations = records.map { recordName, recordType in
      Components.Schemas.RecordOperation(
        operationType: .forceDelete,
        record: .init(
          recordName: recordName,
          recordType: recordType
        )
      )
    }

    return try await modifyRecords(operations: operations, atomic: atomic)
  }

  // MARK: - Private Helpers

  /// Convert FieldValue dictionary to Components.Schemas.Record.fieldsPayload
  private func convertFieldsToComponents(
    _ fields: [String: FieldValue]
  ) -> Components.Schemas.Record.fieldsPayload {
    let componentFields = fields.mapValues { $0.toComponentsFieldValue() }
    return Components.Schemas.Record.fieldsPayload(additionalProperties: componentFields)
  }
}
