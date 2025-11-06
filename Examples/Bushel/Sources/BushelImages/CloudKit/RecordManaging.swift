import Foundation
import MistKit

/// Protocol defining core CloudKit record management operations
///
/// This protocol provides a testable abstraction for CloudKit operations.
/// Conforming types must implement the two core operations, while all other
/// functionality (listing, syncing, deleting) is provided through protocol extensions.
protocol RecordManaging {
    /// Query records of a specific type from CloudKit
    ///
    /// - Parameter recordType: The CloudKit record type to query
    /// - Returns: Array of record information for all matching records
    /// - Throws: CloudKit errors if the query fails
    func queryRecords(recordType: String) async throws -> [RecordInfo]

    /// Execute a batch of record operations
    ///
    /// Handles batching operations to respect CloudKit's 200 operations/request limit.
    /// Provides detailed progress reporting and error tracking.
    ///
    /// - Parameters:
    ///   - operations: Array of record operations to execute
    ///   - recordType: The record type being operated on (for logging)
    /// - Throws: CloudKit errors if the batch operations fail
    func executeBatchOperations(_ operations: [RecordOperation], recordType: String) async throws
}
