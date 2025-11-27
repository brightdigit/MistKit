import Foundation
import MistKit

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
    var fileSize: Int

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

    /// When the source last updated this record (nil if unknown)
    var sourceUpdatedAt: Date?

    /// CloudKit record name based on build number (e.g., "RestoreImage-23C71")
    var recordName: String {
        "RestoreImage-\(buildNumber)"
    }
}

// MARK: - CloudKitRecord Conformance

extension RestoreImageRecord: CloudKitRecord {
    static var cloudKitRecordType: String { "RestoreImage" }

    func toCloudKitFields() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "version": .string(version),
            "buildNumber": .string(buildNumber),
            "releaseDate": .date(releaseDate),
            "downloadURL": .string(downloadURL),
            "fileSize": .int64(fileSize),
            "sha256Hash": .string(sha256Hash),
            "sha1Hash": .string(sha1Hash),
            "isPrerelease": .from(isPrerelease),
            "source": .string(source)
        ]

        // Optional fields
        if let isSigned {
            fields["isSigned"] = .from(isSigned)
        }

        if let notes {
            fields["notes"] = .string(notes)
        }

        if let sourceUpdatedAt {
            fields["sourceUpdatedAt"] = .date(sourceUpdatedAt)
        }

        return fields
    }

    static func from(recordInfo: RecordInfo) -> Self? {
        guard let version = recordInfo.fields["version"]?.stringValue,
              let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
              let releaseDate = recordInfo.fields["releaseDate"]?.dateValue,
              let downloadURL = recordInfo.fields["downloadURL"]?.stringValue,
              let fileSize = recordInfo.fields["fileSize"]?.intValue,
              let sha256Hash = recordInfo.fields["sha256Hash"]?.stringValue,
              let sha1Hash = recordInfo.fields["sha1Hash"]?.stringValue,
              let source = recordInfo.fields["source"]?.stringValue
        else {
            return nil
        }

        return RestoreImageRecord(
            version: version,
            buildNumber: buildNumber,
            releaseDate: releaseDate,
            downloadURL: downloadURL,
            fileSize: fileSize,
            sha256Hash: sha256Hash,
            sha1Hash: sha1Hash,
            isSigned: recordInfo.fields["isSigned"]?.boolValue,
            isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
            source: source,
            notes: recordInfo.fields["notes"]?.stringValue,
            sourceUpdatedAt: recordInfo.fields["sourceUpdatedAt"]?.dateValue
        )
    }

    static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
        let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
        let signed = recordInfo.fields["isSigned"]?.boolValue ?? false
        let prerelease = recordInfo.fields["isPrerelease"]?.boolValue ?? false
        let source = recordInfo.fields["source"]?.stringValue ?? "Unknown"
        let size = recordInfo.fields["fileSize"]?.intValue ?? 0

        let signedStr = signed ? "✅ Signed" : "❌ Unsigned"
        let prereleaseStr = prerelease ? "[Beta/RC]" : ""
        let sizeStr = formatFileSize(size)

        var output = "    \(build) \(prereleaseStr)\n"
        output += "      \(signedStr) | Size: \(sizeStr) | Source: \(source)"
        return output
    }

    private static func formatFileSize(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else {
            let mb = Double(bytes) / 1_000_000
            return String(format: "%.0f MB", mb)
        }
    }
}
