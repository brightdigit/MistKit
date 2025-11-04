import Foundation

/// Represents an Xcode release with macOS requirements and bundled Swift version
struct XcodeVersionRecord: Codable, Sendable {
    /// Xcode version (e.g., "15.1", "15.2 Beta 3")
    var version: String

    /// Build identifier (e.g., "15C65")
    var buildNumber: String

    /// Release date
    var releaseDate: Date

    /// Optional developer.apple.com download link
    var downloadURL: String?

    /// Download size in bytes
    var fileSize: Int64?

    /// Beta/RC indicator
    var isPrerelease: Bool

    /// Reference to minimum RestoreImage record required (recordName)
    var minimumMacOS: String?

    /// Reference to bundled Swift compiler (recordName)
    var includedSwiftVersion: String?

    /// JSON of SDK versions: {"macOS": "14.2", "iOS": "17.2", "watchOS": "10.2"}
    var sdkVersions: String?

    /// Release notes or additional info
    var notes: String?

    /// CloudKit record name based on build number (e.g., "XcodeVersion-15C65")
    var recordName: String {
        "XcodeVersion-\(buildNumber)"
    }
}
