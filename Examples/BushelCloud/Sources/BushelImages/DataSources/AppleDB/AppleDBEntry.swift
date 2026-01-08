import Foundation

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
