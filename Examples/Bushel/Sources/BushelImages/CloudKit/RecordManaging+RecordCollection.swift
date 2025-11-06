import Foundation
import MistKit

/// Default implementations for RecordManaging when conforming to CloudKitRecordCollection
///
/// Provides generic implementations using variadic generics to work with the RecordTypes tuple.
extension RecordManaging where Self: CloudKitRecordCollection {
    /// Synchronize all records to CloudKit using the types defined in RecordTypes
    ///
    /// This method uses reflection on the RecordTypes tuple to sync each type's records.
    /// Records are passed as type-erased `[any CloudKitRecord]` arrays.
    ///
    /// - Parameter recordsByType: Dictionary mapping record type names to arrays of records
    /// - Throws: CloudKit errors or serialization errors
    ///
    /// ## Example
    ///
    /// ```swift
    /// try await service.syncAllRecords([
    ///     "RestoreImage": restoreImages,
    ///     "XcodeVersion": xcodeVersions,
    ///     "SwiftVersion": swiftVersions
    /// ])
    /// ```
    func syncAllRecords(_ recordsByType: [String: [any CloudKitRecord]]) async throws {
        // Extract record types from the tuple using Mirror reflection
        let recordTypes = extractRecordTypes(from: Self.RecordTypes.self)

        for recordType in recordTypes {
            let typeName = recordType.cloudKitRecordType
            guard let records = recordsByType[typeName] else {
                continue
            }

            // Convert type-erased records back to concrete type for generic sync()
            let operations = records.map { record in
                RecordOperation(
                    operationType: .forceReplace,
                    recordType: typeName,
                    recordName: record.recordName,
                    fields: record.toCloudKitFields()
                )
            }

            try await executeBatchOperations(operations, recordType: typeName)
        }
    }

    /// List all records across all types defined in RecordTypes
    ///
    /// Uses reflection on RecordTypes tuple to display each type's records.
    /// Prints a summary at the end.
    ///
    /// - Throws: CloudKit errors
    func listAllRecords() async throws {
        let recordTypes = extractRecordTypes(from: Self.RecordTypes.self)
        var totalCount = 0
        var countsByType: [String: Int] = [:]

        for recordType in recordTypes {
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
        for recordType in recordTypes {
            let typeName = recordType.cloudKitRecordType
            let count = countsByType[typeName] ?? 0
            print("    • \(typeName): \(count)")
        }
        print("")
    }

    /// Extract CloudKitRecord types from a tuple type using reflection
    ///
    /// This helper uses Swift's Mirror to iterate through tuple elements at compile time.
    /// While the tuple itself uses variadic generics, we need reflection to access the types at runtime.
    ///
    /// - Parameter tupleType: The tuple type (e.g., `(RestoreImageRecord, XcodeVersionRecord).self`)
    /// - Returns: Array of CloudKitRecord types
    private func extractRecordTypes(from tupleType: Any.Type) -> [any CloudKitRecord.Type] {
        var types: [any CloudKitRecord.Type] = []

        // Use Mirror to reflect on the tuple's metatype
        let mirror = Mirror(reflecting: tupleType)

        for child in mirror.children {
            if let recordType = child.value as? any CloudKitRecord.Type {
                types.append(recordType)
            }
        }

        return types
    }
}
