import Foundation

/// Errors that can occur during BushelCloudKitService operations
enum BushelCloudKitError: LocalizedError {
    case privateKeyFileNotFound(path: String)
    case privateKeyFileReadFailed(path: String, error: Error)
    case invalidMetadataRecord(recordName: String)

    var errorDescription: String? {
        switch self {
        case .privateKeyFileNotFound(let path):
            return "Private key file not found at path: \(path)"
        case .privateKeyFileReadFailed(let path, let error):
            return "Failed to read private key file at \(path): \(error.localizedDescription)"
        case .invalidMetadataRecord(let recordName):
            return "Invalid DataSourceMetadata record: \(recordName) (missing required fields)"
        }
    }
}
