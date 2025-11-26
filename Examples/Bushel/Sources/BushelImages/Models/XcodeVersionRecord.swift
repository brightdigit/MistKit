import Foundation
import MistKit

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
    var fileSize: Int?

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

// MARK: - CloudKitRecord Conformance

extension XcodeVersionRecord: CloudKitRecord {
    static var cloudKitRecordType: String { "XcodeVersion" }

    func toCloudKitFields() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "version": .string(version),
            "buildNumber": .string(buildNumber),
            "releaseDate": .date(releaseDate),
            "isPrerelease": FieldValue(booleanValue: isPrerelease)
        ]

        // Optional fields
        if let downloadURL {
            fields["downloadURL"] = .string(downloadURL)
        }

        if let fileSize {
            fields["fileSize"] = .int64(fileSize)
        }

        if let minimumMacOS {
            fields["minimumMacOS"] = .reference(FieldValue.Reference(
                recordName: minimumMacOS,
                action: nil
            ))
        }

        if let includedSwiftVersion {
            fields["includedSwiftVersion"] = .reference(FieldValue.Reference(
                recordName: includedSwiftVersion,
                action: nil
            ))
        }

        if let sdkVersions {
            fields["sdkVersions"] = .string(sdkVersions)
        }

        if let notes {
            fields["notes"] = .string(notes)
        }

        return fields
    }

    static func from(recordInfo: RecordInfo) -> Self? {
        guard let version = recordInfo.fields["version"]?.stringValue,
              let buildNumber = recordInfo.fields["buildNumber"]?.stringValue,
              let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
        else {
            return nil
        }

        return XcodeVersionRecord(
            version: version,
            buildNumber: buildNumber,
            releaseDate: releaseDate,
            downloadURL: recordInfo.fields["downloadURL"]?.stringValue,
            fileSize: recordInfo.fields["fileSize"]?.intValue,
            isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
            minimumMacOS: recordInfo.fields["minimumMacOS"]?.referenceValue?.recordName,
            includedSwiftVersion: recordInfo.fields["includedSwiftVersion"]?.referenceValue?.recordName,
            sdkVersions: recordInfo.fields["sdkVersions"]?.stringValue,
            notes: recordInfo.fields["notes"]?.stringValue
        )
    }

    static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
        let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
        let build = recordInfo.fields["buildNumber"]?.stringValue ?? "Unknown"
        let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
        let size = recordInfo.fields["fileSize"]?.intValue ?? 0

        let dateStr = releaseDate.map { formatDate($0) } ?? "Unknown"
        let sizeStr = formatFileSize(size)

        var output = "\n  \(version) (Build \(build))\n"
        output += "    Released: \(dateStr) | Size: \(sizeStr)"
        return output
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
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
