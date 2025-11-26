import Foundation
import MistKit

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

// MARK: - CloudKitRecord Conformance

extension SwiftVersionRecord: CloudKitRecord {
    static var cloudKitRecordType: String { "SwiftVersion" }

    func toCloudKitFields() -> [String: FieldValue] {
        var fields: [String: FieldValue] = [
            "version": .string(version),
            "releaseDate": .date(releaseDate),
            "isPrerelease": .from(isPrerelease)
        ]

        // Optional fields
        if let downloadURL {
            fields["downloadURL"] = .string(downloadURL)
        }

        if let notes {
            fields["notes"] = .string(notes)
        }

        return fields
    }

    static func from(recordInfo: RecordInfo) -> Self? {
        guard let version = recordInfo.fields["version"]?.stringValue,
              let releaseDate = recordInfo.fields["releaseDate"]?.dateValue
        else {
            return nil
        }

        return SwiftVersionRecord(
            version: version,
            releaseDate: releaseDate,
            downloadURL: recordInfo.fields["downloadURL"]?.stringValue,
            isPrerelease: recordInfo.fields["isPrerelease"]?.boolValue ?? false,
            notes: recordInfo.fields["notes"]?.stringValue
        )
    }

    static func formatForDisplay(_ recordInfo: RecordInfo) -> String {
        let version = recordInfo.fields["version"]?.stringValue ?? "Unknown"
        let releaseDate = recordInfo.fields["releaseDate"]?.dateValue

        let dateStr = releaseDate.map { formatDate($0) } ?? "Unknown"

        var output = "\n  Swift \(version)\n"
        output += "    Released: \(dateStr)"
        return output
    }

    private static func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
