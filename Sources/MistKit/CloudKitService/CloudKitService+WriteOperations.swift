//
//  CloudKitService+WriteOperations.swift
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
internal import OpenAPIRuntime

#if canImport(FoundationNetworking)
  internal import FoundationNetworking
#endif

#if !os(WASI)
  internal import OpenAPIURLSession
#endif

extension CloudKitService {
  /// Inspect a batch of API record operations and return a `QuotaHint` for
  /// the first record whose JSON-encoded size exceeds CloudKit's per-record
  /// limit. Returns `nil` if every record is within bounds — which is the
  /// usual case when the server's `QUOTA_EXCEEDED` is caused by storage-quota
  /// exhaustion rather than per-record size.
  private static func recordSizeQuotaHint(
    for apiOperations: [Components.Schemas.RecordOperation]
  ) -> QuotaHint? {
    for (index, operation) in apiOperations.enumerated() {
      guard let record = operation.record,
        let encoded = try? JSONEncoder.shared.encode(record),
        encoded.count > maxRecordDataBytes
      else { continue }
      return .recordExceedsSizeLimit(
        operationIndex: index,
        encodedBytes: encoded.count,
        maxBytes: maxRecordDataBytes
      )
    }
    return nil
  }

  /// Modify (create, update, or delete) CloudKit records
  /// - Parameters:
  ///   - operations: Array of record operations to perform
  ///   - atomic: When true, the entire batch fails if any single operation fails (default: false)
  ///   - database: The CloudKit database scope to modify (`.public`, `.private`, `.shared`)
  /// - Returns: Array of RecordInfo for the modified records
  /// - Throws: CloudKitError if the operation fails
  public func modifyRecords(
    _ operations: [RecordOperation],
    atomic: Bool = false,
    database: Database
  ) async throws(CloudKitError) -> [RecordInfo] {
    let apiOperations: [Components.Schemas.RecordOperation]
    do {
      apiOperations = try operations.map {
        try Components.Schemas.RecordOperation(from: $0)
      }
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError
    } catch {
      throw CloudKitError.underlyingError(error)
    }

    do {
      let client = try self.client(for: database)
      let response = try await client.modifyRecords(
        .init(
          path: .init(
            version: "1",
            container: containerIdentifier,
            environment: .init(from: environment),
            database: .init(from: database)
          ),
          body: .json(
            .init(
              operations: apiOperations,
              atomic: atomic
            )
          )
        )
      )

      let modifyResponse: Components.Schemas.ModifyResponse =
        try await responseProcessor.processModifyRecordsResponse(response)

      return modifyResponse.records?.compactMap { RecordInfo(from: $0) }
        ?? []
    } catch let cloudKitError as CloudKitError {
      throw cloudKitError.addingQuotaHint(
        Self.recordSizeQuotaHint(for: apiOperations)
      )
    } catch {
      throw CloudKitError.underlyingError(error)
    }
  }

  /// Create a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to create
  ///   - recordName: Optional unique record name
  ///   - fields: Dictionary of field names to FieldValue
  ///   - database: The CloudKit database scope to write to (`.public`, `.private`, `.shared`)
  /// - Returns: RecordInfo for the created record
  /// - Throws: CloudKitError if the operation fails
  ///
  /// # Example
  /// ```swift
  /// let article = try await service.createRecord(
  ///   recordType: "Article",
  ///   fields: ["title": .string("Hello, CloudKit")],
  ///   database: .private
  /// )
  /// ```
  public func createRecord(
    recordType: String,
    recordName: String? = nil,
    fields: [String: FieldValue],
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.create(
      recordType: recordType,
      recordName: recordName,
      fields: fields
    )

    let results = try await modifyRecords([operation], database: database)
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
  ///   - database: The CloudKit database scope to write to (`.public`, `.private`, `.shared`)
  /// - Returns: RecordInfo for the updated record
  /// - Throws: CloudKitError if the operation fails
  ///
  /// # Example
  /// ```swift
  /// let updated = try await service.updateRecord(
  ///   recordType: "Article",
  ///   recordName: existing.recordName,
  ///   fields: ["title": .string("Renamed")],
  ///   recordChangeTag: existing.recordChangeTag,
  ///   database: .private
  /// )
  /// ```
  public func updateRecord(
    recordType: String,
    recordName: String,
    fields: [String: FieldValue],
    recordChangeTag: String? = nil,
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.update(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag
    )

    let results = try await modifyRecords([operation], database: database)
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
  ///   - database: The CloudKit database scope to delete from (`.public`, `.private`, `.shared`)
  /// - Throws: CloudKitError if the operation fails
  public func deleteRecord(
    recordType: String,
    recordName: String,
    recordChangeTag: String? = nil,
    database: Database
  ) async throws(CloudKitError) {
    let operation = RecordOperation.delete(
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag
    )

    _ = try await modifyRecords([operation], database: database)
  }
}
