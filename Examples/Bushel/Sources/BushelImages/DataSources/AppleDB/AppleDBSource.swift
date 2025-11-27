import Foundation

/// Represents an installation source (IPSW, OTA, or IA)
struct AppleDBSource: Codable {
    let type: String        // "ipsw", "ota", "ia"
    let deviceMap: [String]
    let links: [AppleDBLink]?
    let hashes: AppleDBHashes?
    let size: Int?
    let prerequisiteBuild: String?
}
