import Foundation
import MistKit

extension RecordManaging {
    // MARK: - Query Operations

    /// Query a specific DataSourceMetadata record
    ///
    /// **MistKit Pattern**: Query all metadata records and filter by record name
    /// Record name format: "metadata-{sourceName}-{recordType}"
    func queryDataSourceMetadata(source: String, recordType: String) async throws -> DataSourceMetadata? {
        let targetRecordName = "metadata-\(source)-\(recordType)"
        let results = try await query(DataSourceMetadata.self) { record in
            record.recordName == targetRecordName
        }
        return results.first
    }
}
