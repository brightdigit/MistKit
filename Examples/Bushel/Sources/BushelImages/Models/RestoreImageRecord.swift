import Foundation

/// Represents a macOS IPSW restore image for Apple Virtualization framework
struct RestoreImageRecord: Codable, Sendable {
    /// macOS version (e.g., "14.2.1", "15.0 Beta 3")
    var version: String

    /// Build identifier (e.g., "23C71", "24A5264n")
    var buildNumber: String

    /// Official release date
    var releaseDate: Date

    /// Direct IPSW download link
    var downloadURL: String

    /// File size in bytes
    var fileSize: Int64

    /// SHA-256 checksum for integrity verification
    var sha256Hash: String

    /// SHA-1 hash (from MESU/ipsw.me for compatibility)
    var sha1Hash: String

    /// Whether Apple still signs this restore image (nil if unknown)
    var isSigned: Bool?

    /// Beta/RC release indicator
    var isPrerelease: Bool

    /// Data source: "ipsw.me", "mrmacintosh.com", "mesu.apple.com"
    var source: String

    /// Additional metadata or release notes
    var notes: String?

    /// CloudKit record name based on build number (e.g., "RestoreImage-23C71")
    var recordName: String {
        "RestoreImage-\(buildNumber)"
    }
}
