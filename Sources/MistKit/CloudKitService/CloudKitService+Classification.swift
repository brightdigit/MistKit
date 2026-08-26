//
//  CloudKitService+Classification.swift
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

/// Helpers for tracking creates vs updates in `modifyRecords` responses.
///
/// CloudKit's `/records/modify` endpoint does not include any indicator of
/// whether each operation produced a newly created record or updated an
/// existing one. The pattern in this extension implements the documented
/// pre-fetch + classify workaround:
///
/// 1. Call `fetchExistingRecordNames(recordType:)` to discover which records
///    already exist.
/// 2. Build an `OperationClassification` from the proposed operations and the
///    existing names.
/// 3. Call `modifyRecords(_:classification:atomic:)` to perform the modify and
///    receive a `BatchSyncResult` with creates/updates/failures already
///    partitioned.
extension CloudKitService {
  /// Fetch the set of record names that already exist for a record type.
  ///
  /// Used as the first step of the pre-fetch + classify pattern for tracking
  /// creates vs updates in batch modify operations. Internally this calls
  /// `queryRecords(_:limit:database:)` and projects the results down to a
  /// `Set<String>` of record names.
  ///
  /// - Important: This issues a single `queryRecords` call. CloudKit caps a
  ///   single response at 200 records, so for larger record types you must
  ///   paginate at the call site or use a custom query.
  ///
  /// - Parameters:
  ///   - recordType: The CloudKit record type to scan.
  ///   - limit: Optional maximum number of records to fetch (1-200). Defaults
  ///     to CloudKit's per-request maximum.
  ///   - database: The CloudKit database scope to query (`.public`, `.private`, `.shared`).
  /// - Returns: Set of existing record names.
  /// - Throws: `CloudKitError` if the underlying query fails.
  public func fetchExistingRecordNames(
    recordType: String,
    limit: Int? = nil,
    database: Database
  ) async throws(CloudKitError) -> Set<String> {
    let result: QueryResult = try await queryRecords(
      Query(recordType: recordType),
      limit: limit ?? Self.maxRecordsPerRequest,
      database: database
    )
    return Set(result.records.map(\.recordName))
  }

  /// Modify CloudKit records and partition the response into creates,
  /// updates, failures, and unclassified records.
  ///
  /// This overload calls `modifyRecords(_:atomic:)` internally and then
  /// uses the supplied `OperationClassification` to attribute each returned
  /// `RecordInfo` to a category. It does not issue any extra CloudKit
  /// requests beyond the modify itself.
  ///
  /// ## Example
  /// ```swift
  /// let existing = try await service.fetchExistingRecordNames(recordType: "Article")
  /// let classification = OperationClassification(
  ///   operations: operations,
  ///   existingRecordNames: existing
  /// )
  /// let result = try await service.modifyRecords(
  ///   operations,
  ///   classification: classification
  /// )
  /// print("Created: \(result.createdCount)")
  /// print("Updated: \(result.updatedCount)")
  /// print("Failed:  \(result.failedCount)")
  /// ```
  ///
  /// - Parameters:
  ///   - operations: Record operations to perform.
  ///   - classification: Pre-computed classification of operations as creates
  ///     vs updates, typically from `fetchExistingRecordNames(recordType:)`.
  ///   - atomic: When `true`, the entire batch fails if any single operation
  ///     fails (default: `false`).
  ///   - database: The CloudKit database scope to modify (`.public`, `.private`, `.shared`).
  /// - Returns: A `BatchSyncResult` partitioning the response.
  /// - Throws: `CloudKitError` if the modify request fails.
  public func modifyRecords(
    _ operations: [RecordOperation],
    classification: OperationClassification,
    atomic: Bool = false,
    database: Database
  ) async throws(CloudKitError) -> BatchSyncResult {
    let results = try await modifyRecords(
      operations,
      atomic: atomic,
      database: database
    )
    return BatchSyncResult(results: results, classification: classification)
  }
}
