//
//  CloudKitService+WriteOperations.swift
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
import OpenAPIRuntime
import OpenAPIURLSession

@available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
extension CloudKitService {
  /// Modify (create, update, or delete) CloudKit records
  /// - Parameter operations: Array of record operations to perform
  /// - Returns: Array of RecordInfo for the modified records
  /// - Throws: CloudKitError if the operation fails
  public func modifyRecords(
    _ operations: [RecordOperation]
  ) async throws(CloudKitError) -> [RecordInfo] {
    do {
      // Convert public RecordOperation types to internal OpenAPI types
      let apiOperations = operations.map { $0.toComponentsRecordOperation() }

      // Call the underlying OpenAPI client
      let response = try await client.modifyRecords(
        .init(
          path: .init(
            version: "1",
            container: containerIdentifier,
            environment: environment.toComponentsEnvironment(),
            database: database.toComponentsDatabase()
          ),
          body: .json(
            .init(
              operations: apiOperations,
              atomic: false  // Continue on individual failures
            )
          )
        )
      )

      // Process the response
      let modifyResponse: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)

      // Convert response records to RecordInfo
      return modifyResponse.records?.compactMap { RecordInfo(from: $0) } ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      // Preserve original error context
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Create a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to create (e.g., "RestoreImage")
  ///   - recordName: Optional unique record name (if nil, a UUID will be generated)
  ///   - fields: Dictionary of field names to FieldValue
  /// - Returns: RecordInfo for the created record
  /// - Throws: CloudKitError if the operation fails
  public func createRecord(
    recordType: String,
    recordName: String? = nil,
    fields: [String: FieldValue]
  ) async throws(CloudKitError) -> RecordInfo {
    let finalRecordName = recordName ?? UUID().uuidString
    let operation = RecordOperation.create(
      recordType: recordType,
      recordName: finalRecordName,
      fields: fields
    )

    let results = try await modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Update a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to update
  ///   - recordName: The unique record name
  ///   - fields: Dictionary of field names to FieldValue
  ///   - recordChangeTag: Optional change tag for optimistic locking
  /// - Returns: RecordInfo for the updated record
  /// - Throws: CloudKitError if the operation fails
  public func updateRecord(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String? = nil
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.update(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag
    )

    let results = try await modifyRecords([operation])
    guard let record = results.first else {
      throw CloudKitError.invalidResponse
    }
    return record
  }

  /// Delete a single record from CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to delete
  ///   - recordName: The unique record name
  ///   - recordChangeTag: Optional change tag for optimistic locking
  /// - Throws: CloudKitError if the operation fails
  public func deleteRecord(
    recordType: String,
    recordName: String,
    recordChangeTag: String? = nil
  ) async throws(CloudKitError) {
    let operation = RecordOperation.delete(
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag
    )

    _ = try await modifyRecords([operation])
  }
}
