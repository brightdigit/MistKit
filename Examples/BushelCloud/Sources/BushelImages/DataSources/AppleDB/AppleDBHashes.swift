import Foundation

/// Represents file hashes for verification
struct AppleDBHashes: Codable {
    let sha1: String?
    let sha2_256: String? // JSON key is "sha2-256"

    enum CodingKeys: String, CodingKey {
        case sha1
        case sha2_256 = "sha2-256"
    }
}
