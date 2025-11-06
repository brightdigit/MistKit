import Foundation
import MistKit

/// Protocol for services that manage a collection of CloudKit record types using variadic generics
///
/// Conforming types define which record types they manage using parameter packs,
/// enabling generic operations that work across all managed types without hardcoding specific types.
///
/// ## Example
///
/// ```swift
/// extension BushelCloudKitService: CloudKitRecordCollection {
///     typealias RecordTypes = (RestoreImageRecord, XcodeVersionRecord, SwiftVersionRecord)
/// }
///
/// // Now listAllRecords() automatically iterates through these types
/// try await service.listAllRecords()
/// ```
protocol CloudKitRecordCollection {
    /// Parameter pack defining all CloudKit record types managed by this service
    ///
    /// Define the complete set of record types this service works with.
    /// These types will be used for batch operations like listing all records.
    associatedtype RecordTypes
}
