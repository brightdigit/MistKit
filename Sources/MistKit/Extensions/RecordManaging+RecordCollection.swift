//
//  RecordManaging+RecordCollection.swift
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

/// Default implementations for RecordManaging when conforming to CloudKitRecordCollection
///
/// Provides generic implementations using Swift variadic generics (parameter packs)
/// to iterate through CloudKit record types at compile time without runtime reflection.
@available(macOS 14.0, iOS 17.0, tvOS 17.0, watchOS 10.0, *)
extension RecordManaging where Self: CloudKitRecordCollection {
  /// Synchronize multiple record types to CloudKit using variadic generics
  ///
  /// This method uses Swift parameter packs to accept multiple arrays of different
  /// CloudKit record types, providing compile-time type safety without dictionaries.
  ///
  /// - Parameter records: Variadic arrays of CloudKit records (one per record type)
  /// - Throws: CloudKit errors or serialization errors
  ///
  /// ## Example
  ///
  /// ```swift
  /// try await service.syncAllRecords(
  ///     restoreImages,   // [RestoreImageRecord]
  ///     xcodeVersions,   // [XcodeVersionRecord]
  ///     swiftVersions    // [SwiftVersionRecord]
  /// )
  /// ```
  ///
  /// ## Type Safety Benefits
  ///
  /// - No string keys to mistype
  /// - Compiler enforces concrete types
  /// - Each array maintains its specific type
  /// - Impossible to pass wrong record type
  public func syncAllRecords<each RecordType: CloudKitRecord>(
    _ records: repeat [each RecordType]
  ) async throws {
    // Swift 6.0+ pack iteration
    // swift-format-ignore: UseWhereClausesInForLoops
    for recordArray in repeat each records {
      guard !recordArray.isEmpty else { continue }
      // Extract type information from first record
      let firstRecord = recordArray[0]
      let typeName = type(of: firstRecord).cloudKitRecordType

      // Convert records to operations
      let operations = recordArray.map { record in
        RecordOperation(
          operationType: .forceReplace,
          recordType: typeName,
          recordName: record.recordName,
          fields: record.toCloudKitFields()
        )
      }

      // Execute batch operation for this record type
      try await executeBatchOperations(operations, recordType: typeName)
    }
  }

  /// List all records across all types defined in RecordTypeSet
  ///
  /// Uses Swift variadic generics to iterate through record types at compile time.
  /// Prints a summary at the end.
  ///
  /// - Throws: CloudKit errors
  public func listAllRecords() async throws {
    var totalCount = 0
    var countsByType: [String: Int] = [:]
    var recordTypesList: [any CloudKitRecord.Type] = []

    // Use RecordTypeSet to iterate through types without reflection
    try await Self.recordTypes.forEach { recordType in
      recordTypesList.append(recordType)
      let typeName = recordType.cloudKitRecordType
      let records = try await queryRecords(recordType: typeName)
      countsByType[typeName] = records.count
      totalCount += records.count

      // Display records using the type's formatForDisplay
      print("\n\(typeName) (\(records.count) total)")
      print(String(repeating: "=", count: 80))

      for record in records {
        print(recordType.formatForDisplay(record))
      }
    }

    // Print summary
    print("\n📊 Summary")
    print(String(repeating: "=", count: 80))
    print("  Total Records: \(totalCount)")
    for recordType in recordTypesList {
      let typeName = recordType.cloudKitRecordType
      let count = countsByType[typeName] ?? 0
      print("    • \(typeName): \(count)")
    }
    print("")
  }

  /// Delete all records across all types defined in RecordTypeSet
  ///
  /// Uses Swift variadic generics to iterate through record types at compile time.
  /// Queries all records for each type and deletes them in batches.
  ///
  /// - Throws: CloudKit errors
  ///
  /// ## Example
  ///
  /// ```swift
  /// try await service.deleteAllRecords()
  /// ```
  public func deleteAllRecords() async throws {
    var totalDeleted = 0
    var deletedByType: [String: Int] = [:]

    print("\n🗑️  Deleting all records across all types...")

    // Use RecordTypeSet to iterate through types without reflection
    try await Self.recordTypes.forEach { recordType in
      let typeName = recordType.cloudKitRecordType
      let records = try await queryRecords(recordType: typeName)

      guard !records.isEmpty else {
        print("\n\(typeName): No records to delete")
        return
      }

      print("\n\(typeName): Deleting \(records.count) record(s)...")

      // Create delete operations for all records
      let operations = records.map { record in
        RecordOperation(
          operationType: .delete,
          recordType: typeName,
          recordName: record.recordName,
          fields: [:]
        )
      }

      // Execute batch delete operations
      try await executeBatchOperations(operations, recordType: typeName)

      deletedByType[typeName] = records.count
      totalDeleted += records.count
    }

    // Print summary
    print("\n📊 Deletion Summary")
    print(String(repeating: "=", count: 80))
    print("  Total Records Deleted: \(totalDeleted)")
    for (typeName, count) in deletedByType.sorted(by: { $0.key < $1.key }) {
      print("    • \(typeName): \(count)")
    }
    print("")
  }
}
