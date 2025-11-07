//
//  RecordManaging+Generic.swift
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

public import Foundation

/// Generic extensions for RecordManaging protocol that work with any CloudKitRecord type
///
/// These extensions eliminate the need for type-specific implementations by leveraging
/// the CloudKitRecord protocol's serialization methods.
extension RecordManaging {
  // MARK: - Generic Operations

  /// Sync records of any CloudKitRecord-conforming type to CloudKit
  ///
  /// This generic method eliminates the need for type-specific sync methods.
  /// The model's `toCloudKitFields()` method handles field mapping.
  /// Operations are automatically batched to respect CloudKit's 200 operations/request limit.
  ///
  /// ## Example
  /// ```swift
  /// let swiftRecords: [SwiftVersionRecord] = [...]
  /// try await service.sync(swiftRecords)
  /// ```
  ///
  /// - Parameter records: Array of records conforming to CloudKitRecord
  /// - Throws: CloudKit errors if the sync operation fails
  public func sync<T: CloudKitRecord>(_ records: [T]) async throws {
    let operations = records.map { record in
      RecordOperation(
        operationType: .forceReplace,
        recordType: T.cloudKitRecordType,
        recordName: record.recordName,
        fields: record.toCloudKitFields()
      )
    }

    // Batch operations to respect CloudKit's 200 operations/request limit
    let batches = operations.chunked(into: 200)

    for batch in batches {
      try await executeBatchOperations(batch, recordType: T.cloudKitRecordType)
    }
  }

  /// List records of any CloudKitRecord-conforming type with formatted output
  ///
  /// This generic method queries all records of the specified type and displays
  /// them using the type's `formatForDisplay()` implementation.
  ///
  /// ## Example
  /// ```swift
  /// try await service.list(XcodeVersionRecord.self)
  /// ```
  ///
  /// - Parameters:
  ///   - type: The CloudKitRecord type to list
  /// - Throws: CloudKit errors if the query fails
  public func list<T: CloudKitRecord>(_ type: T.Type) async throws {
    let records = try await queryRecords(recordType: T.cloudKitRecordType)

    print("\n\(T.cloudKitRecordType) (\(records.count) total)")
    print(String(repeating: "=", count: 80))

    guard !records.isEmpty else {
      print("   No records found.")
      return
    }

    for record in records {
      print(T.formatForDisplay(record))
    }
  }

  /// Query and parse records of any CloudKitRecord-conforming type
  ///
  /// This generic method fetches raw CloudKit records and converts them
  /// to strongly-typed model instances using the type's `from(recordInfo:)` method.
  ///
  /// ## Example
  /// ```swift
  /// // Query all Swift versions
  /// let allVersions = try await service.query(SwiftVersionRecord.self)
  ///
  /// // Query with filter
  /// let betas = try await service.query(SwiftVersionRecord.self) { record in
  ///     record.fields["isPrerelease"]?.boolValue == true
  /// }
  /// ```
  ///
  /// - Parameters:
  ///   - type: The CloudKitRecord type to query
  ///   - filter: Optional closure to filter RecordInfo results before parsing
  /// - Returns: Array of parsed model instances (nil records are filtered out)
  /// - Throws: CloudKit errors if the query fails
  public func query<T: CloudKitRecord>(
    _ type: T.Type,
    where filter: (RecordInfo) -> Bool = { _ in true }
  ) async throws -> [T] {
    let records = try await queryRecords(recordType: T.cloudKitRecordType)
    return records.filter(filter).compactMap(T.from)
  }
}
