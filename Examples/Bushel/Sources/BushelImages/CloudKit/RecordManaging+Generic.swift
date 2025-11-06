import Foundation
import MistKit

extension RecordManaging {
    // MARK: - Generic Operations

    /// Sync records of any CloudKitRecord-conforming type to CloudKit
    ///
    /// This generic method eliminates the need for type-specific sync methods.
    /// The model's `toCloudKitFields()` method handles field mapping.
    ///
    /// ## Example
    /// ```swift
    /// let swiftRecords: [SwiftVersionRecord] = [...]
    /// try await service.sync(swiftRecords)
    /// ```
    ///
    /// - Parameter records: Array of records conforming to CloudKitRecord
    /// - Throws: CloudKit errors if the sync operation fails
    func sync<T: CloudKitRecord>(_ records: [T]) async throws {
        let operations = records.map { record in
            RecordOperation(
                operationType: .forceReplace,
                recordType: T.cloudKitRecordType,
                recordName: record.recordName,
                fields: record.toCloudKitFields()
            )
        }
        try await executeBatchOperations(operations, recordType: T.cloudKitRecordType)
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
    func list<T: CloudKitRecord>(_ type: T.Type) async throws {
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
    ///   - filter: Optional closure to filter RecordInfo results
    /// - Returns: Array of parsed model instances (nil records are filtered out)
    /// - Throws: CloudKit errors if the query fails
    func query<T: CloudKitRecord>(
        _ type: T.Type,
        where filter: (RecordInfo) -> Bool = { _ in true }
    ) async throws -> [T] {
        let records = try await queryRecords(recordType: T.cloudKitRecordType)
        return records.filter(filter).compactMap(T.from)
    }
}
