import Foundation

// MARK: - AppleDB Entry

/// Represents a single macOS build entry from AppleDB
struct AppleDBEntry: Codable {
    let osStr: String
    let version: String
    let build: String?  // Some entries may not have a build number
    let uniqueBuild: String?
    let released: String // ISO date or empty string
    let beta: Bool?
    let rc: Bool?
    let `internal`: Bool?
    let deviceMap: [String]
    let signed: SignedStatus
    let sources: [AppleDBSource]?

    enum CodingKeys: String, CodingKey {
        case osStr, version, build, uniqueBuild, released
        case beta, rc
        case `internal` = "internal"
        case deviceMap, signed, sources
    }
}

// MARK: - Signed Status

/// Represents the signing status for a build
/// Can be: array of device IDs, boolean true (all signed), or empty array (none signed)
enum SignedStatus: Codable {
    case devices([String]) // Array of signed device IDs
    case all(Bool)         // true = all devices signed
    case none              // Empty array = not signed

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        // Try decoding as array first
        if let devices = try? container.decode([String].self) {
            if devices.isEmpty {
                self = .none
            } else {
                self = .devices(devices)
            }
        }
        // Then try boolean
        else if let allSigned = try? container.decode(Bool.self) {
            self = .all(allSigned)
        }
        // Default to none if decoding fails
        else {
            self = .none
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .devices(let devices):
            try container.encode(devices)
        case .all(let value):
            try container.encode(value)
        case .none:
            try container.encode([String]())
        }
    }

    /// Check if a specific device identifier is signed
    func isSigned(for deviceIdentifier: String) -> Bool {
        switch self {
        case .devices(let devices):
            return devices.contains(deviceIdentifier)
        case .all(true):
            return true
        case .all(false), .none:
            return false
        }
    }
}

// MARK: - Source

/// Represents an installation source (IPSW, OTA, or IA)
struct AppleDBSource: Codable {
    let type: String        // "ipsw", "ota", "ia"
    let deviceMap: [String]
    let links: [AppleDBLink]?
    let hashes: AppleDBHashes?
    let size: Int?
    let prerequisiteBuild: String?
}

// MARK: - Link

/// Represents a download link for a source
struct AppleDBLink: Codable {
    let url: String
    let preferred: Bool?
    let active: Bool?
}

// MARK: - Hashes

/// Represents file hashes for verification
struct AppleDBHashes: Codable {
    let sha1: String?
    let sha2_256: String? // JSON key is "sha2-256"

    enum CodingKeys: String, CodingKey {
        case sha1
        case sha2_256 = "sha2-256"
    }
}

// MARK: - GitHub API Response

/// Response from GitHub API for commits
struct GitHubCommitsResponse: Codable {
    let sha: String
    let commit: GitHubCommit
}

struct GitHubCommit: Codable {
    let committer: GitHubCommitter
    let message: String
}

struct GitHubCommitter: Codable {
    let date: String // ISO 8601 format
}
