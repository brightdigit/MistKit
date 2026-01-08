import Foundation

/// IPSW metadata from TheAppleWiki
struct IPSWVersion: Codable, Sendable {
    let version: String
    let buildNumber: String
    let deviceModel: String
    let fileName: String
    let fileSize: String
    let sha1: String
    let releaseDate: Date?
    let url: URL?

    // MARK: - Computed Properties

    /// Parse file size string to Int for CloudKit
    /// Examples: "10.2 GB" -> bytes, "1.5 MB" -> bytes
    var fileSizeInBytes: Int? {
        let components = fileSize.components(separatedBy: " ")
        guard components.count == 2,
              let size = Double(components[0]) else {
            return nil
        }

        let unit = components[1].uppercased()
        let multiplier: Double = switch unit {
        case "GB": 1_000_000_000
        case "MB": 1_000_000
        case "KB": 1_000
        case "BYTES", "B": 1
        default: 0
        }

        guard multiplier > 0 else { return nil }
        return Int(size * multiplier)
    }

    /// Detect if this is a VirtualMac device
    var isVirtualMac: Bool {
        deviceModel.contains("VirtualMac")
    }

    /// Detect if this is a prerelease version (beta, RC, etc.)
    var isPrerelease: Bool {
        let lowercased = version.lowercased()
        return lowercased.contains("beta")
            || lowercased.contains("rc")
            || lowercased.contains("gm seed")
            || lowercased.contains("developer preview")
    }

    /// Validate that all required fields are present
    var isValid: Bool {
        !version.isEmpty
            && !buildNumber.isEmpty
            && !deviceModel.isEmpty
            && !fileName.isEmpty
            && !sha1.isEmpty
            && url != nil
    }
}
