import Foundation
import MistKit

/// Protocol for types that provide iteration over CloudKit record types
///
/// Conforming types provide a `forEach` method for iterating through
/// a collection of CloudKit record types.
protocol RecordTypeIterating {
    /// Iterate through all record types
    ///
    /// - Parameter action: Closure called for each record type
    /// - Throws: Rethrows any errors thrown by the action closure
    func forEach(_ action: (any CloudKitRecord.Type) async throws -> Void) async rethrows
}

/// Lightweight container for CloudKit record types using Swift variadic generics
///
/// This struct captures a parameter pack of `CloudKitRecord` types and provides
/// type-safe iteration over them without runtime reflection.
///
/// ## Example
///
/// ```swift
/// let recordTypes = RecordTypeSet(
///     RestoreImageRecord.self,
///     XcodeVersionRecord.self,
///     SwiftVersionRecord.self
/// )
///
/// recordTypes.forEach { recordType in
///     print(recordType.cloudKitRecordType)
/// }
/// ```
struct RecordTypeSet<each RecordType: CloudKitRecord>: Sendable, RecordTypeIterating {
    /// Initialize with a parameter pack of CloudKit record types
    ///
    /// - Parameter types: Variadic parameter pack of CloudKit record types
    init(_ types: repeat (each RecordType).Type) {}

    /// Iterate through all record types in the parameter pack
    ///
    /// This method uses Swift's `repeat each` pattern to iterate through
    /// the parameter pack at compile time, providing type-safe access to each type.
    ///
    /// - Parameter action: Closure called for each record type
    /// - Throws: Rethrows any errors thrown by the action closure
    func forEach(_ action: (any CloudKitRecord.Type) async throws -> Void) async rethrows {
      try await (repeat action((each RecordType).self))
    }
}
