//
//  CloudKitService+RecordWriteConvenience.swift
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

extension CloudKitService {
  /// Create a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to create
  ///   - recordName: Optional unique record name
  ///   - fields: Dictionary of field names to FieldValue
  ///   - zoneID: Optional target zone (defaults to the request's zone /
  ///     `_defaultZone` when omitted)
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
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.create(
      recordType: recordType,
      recordName: recordName,
      fields: fields
    )

    let results = try await modifyRecords(
      [operation], zoneID: zoneID, database: database
    )
    guard let result = results.first else {
      throw CloudKitError.invalidResponse
    }
    return try result.get()
  }

  /// Update a single record in CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to update
  ///   - recordName: The unique record name
  ///   - fields: Dictionary of field names to FieldValue
  ///   - recordChangeTag: Optional change tag for optimistic locking
  ///   - zoneID: Optional target zone (defaults to the request's zone /
  ///     `_defaultZone` when omitted)
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
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) -> RecordInfo {
    let operation = RecordOperation.update(
      recordType: recordType,
      recordName: recordName,
      fields: fields,
      recordChangeTag: recordChangeTag
    )

    let results = try await modifyRecords(
      [operation], zoneID: zoneID, database: database
    )
    guard let result = results.first else {
      throw CloudKitError.invalidResponse
    }
    return try result.get()
  }

  /// Delete a single record from CloudKit
  /// - Parameters:
  ///   - recordType: The type of record to delete
  ///   - recordName: The unique record name
  ///   - recordChangeTag: Optional change tag for optimistic locking
  ///   - zoneID: Optional target zone (defaults to the request's zone /
  ///     `_defaultZone` when omitted)
  ///   - database: The CloudKit database scope to delete from (`.public`, `.private`, `.shared`)
  /// - Throws: CloudKitError if the operation fails
  public func deleteRecord(
    recordType: String,
    recordName: String,
    recordChangeTag: String? = nil,
    zoneID: ZoneID? = nil,
    database: Database
  ) async throws(CloudKitError) {
    let operation = RecordOperation.delete(
      recordType: recordType,
      recordName: recordName,
      recordChangeTag: recordChangeTag
    )

    let results = try await modifyRecords(
      [operation], zoneID: zoneID, database: database
    )
    for result in results {
      // `get()` rethrows a per-record failure as `recordOperationFailed`.
      _ = try result.get()
    }
  }
}
