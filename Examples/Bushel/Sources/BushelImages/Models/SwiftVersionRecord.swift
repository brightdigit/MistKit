import Foundation

/// Represents a Swift compiler release bundled with Xcode
struct SwiftVersionRecord: Codable, Sendable {
    /// Swift version (e.g., "5.9", "5.10", "6.0")
    var version: String

    /// Release date
    var releaseDate: Date

    /// Optional swift.org toolchain download
    var downloadURL: String?

    /// Beta/snapshot indicator
    var isPrerelease: Bool

    /// Release notes
    var notes: String?

    /// CloudKit record name based on version (e.g., "SwiftVersion-5.9.2")
    var recordName: String {
        "SwiftVersion-\(version)"
    }
}
