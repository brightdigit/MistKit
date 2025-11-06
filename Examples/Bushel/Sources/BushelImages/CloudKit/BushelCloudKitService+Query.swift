import Foundation
import MistKit

extension BushelCloudKitService {
    // MARK: - Query Operations

    /// Query all records of a given type
    func queryRecords(recordType: String) async throws -> [RecordInfo] {
        try await service.queryRecords(recordType: recordType, limit: 1000)
    }

    /// Query a specific DataSourceMetadata record
    ///
    /// **MistKit Pattern**: Query all metadata records and filter by record name
    /// Record name format: "metadata-{sourceName}-{recordType}"
    func queryDataSourceMetadata(source: String, recordType: String) async throws -> DataSourceMetadata? {
        let targetRecordName = "metadata-\(source)-\(recordType)"
        let results = try await service.queryRecords(
            recordType: "DataSourceMetadata",
            limit: 1000
        )

        // Find the specific record we're looking for
        guard let record = results.first(where: { $0.recordName == targetRecordName }) else {
            return nil
        }

        // Parse the CloudKit record back into DataSourceMetadata
        return try parseDataSourceMetadata(from: record)
    }

    // MARK: - Private Helpers

    /// Parse a CloudKit RecordInfo into DataSourceMetadata
    private func parseDataSourceMetadata(from record: RecordInfo) throws(BushelCloudKitError) -> DataSourceMetadata {
        guard let sourceName = record.fields["sourceName"]?.stringValue,
              let recordTypeName = record.fields["recordTypeName"]?.stringValue,
              let lastFetchedAt = record.fields["lastFetchedAt"]?.dateValue
        else {
            throw BushelCloudKitError.invalidMetadataRecord(recordName: record.recordName)
        }

        let sourceUpdatedAt = record.fields["sourceUpdatedAt"]?.dateValue
        let recordCount = record.fields["recordCount"]?.intValue ?? 0
        let fetchDurationSeconds = record.fields["fetchDurationSeconds"]?.doubleValue ?? 0
        let lastError = record.fields["lastError"]?.stringValue

        return DataSourceMetadata(
            sourceName: sourceName,
            recordTypeName: recordTypeName,
            lastFetchedAt: lastFetchedAt,
            sourceUpdatedAt: sourceUpdatedAt,
            recordCount: recordCount,
            fetchDurationSeconds: fetchDurationSeconds,
            lastError: lastError
        )
    }
}
