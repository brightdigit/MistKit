import Foundation
import MistKit

/// Protocol for services that manage a collection of CloudKit record types using variadic generics
///
/// Conforming types define which record types they manage via a `RecordTypeSet` parameter pack,
/// enabling generic operations that work across all managed types without hardcoding specific types.
///
/// ## Example
///
/// ```swift
/// extension BushelCloudKitService: CloudKitRecordCollection {
///     static let recordTypes = RecordTypeSet(
///         RestoreImageRecord.self,
///         XcodeVersionRecord.self,
///         SwiftVersionRecord.self
///     )
/// }
///
/// // Now listAllRecords() automatically iterates through these types
/// try await service.listAllRecords()
/// ```
protocol CloudKitRecordCollection {
    /// Type of the record type set (inferred from static property)
    ///
    /// Must conform to `RecordTypeIterating` to provide `forEach` iteration.
    associatedtype RecordTypeSetType: RecordTypeIterating

    /// Parameter pack defining all CloudKit record types managed by this service
    ///
    /// Define the complete set of record types using `RecordTypeSet`.
    /// These types will be used for batch operations like listing all records.
    static var recordTypes: RecordTypeSetType { get }
}
