import Foundation

/// Represents a download link for a source
struct AppleDBLink: Codable {
    let url: String
    let preferred: Bool?
    let active: Bool?
}
