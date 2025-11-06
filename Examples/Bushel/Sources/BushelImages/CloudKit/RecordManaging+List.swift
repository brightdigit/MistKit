import Foundation
import MistKit

extension RecordManaging {
    // MARK: - List Operations

    /// List all RestoreImage records with formatted output
    func listRestoreImages() async throws {
        let records = try await queryRecords(recordType: "RestoreImage")

        print("\n📀 Restore Images (\(records.count) total)")
        print(String(repeating: "=", count: 80))

        if records.isEmpty {
            print("   No restore images found.")
            return
        }

        // Group by version for better readability
        let grouped = Dictionary(grouping: records) { record -> String in
            record.fields["version"]?.stringValue ?? "Unknown"
        }

        for version in grouped.keys.sorted() {
            let versionRecords = grouped[version] ?? []
            print("\n\(version)")
            print(String(repeating: "-", count: 80))

            for record in versionRecords.sorted(by: {
                ($0.fields["buildNumber"]?.stringValue ?? "") < ($1.fields["buildNumber"]?.stringValue ?? "")
            }) {
                printRestoreImageRecord(record)
            }
        }
    }

    /// List all XcodeVersion records with formatted output
    func listXcodeVersions() async throws {
        let records = try await queryRecords(recordType: "XcodeVersion")

        print("\n🛠️  Xcode Versions (\(records.count) total)")
        print(String(repeating: "=", count: 80))

        if records.isEmpty {
            print("   No Xcode versions found.")
            return
        }

        for record in records.sorted(by: {
            ($0.fields["version"]?.stringValue ?? "") > ($1.fields["version"]?.stringValue ?? "")
        }) {
            printXcodeVersionRecord(record)
        }
    }

    /// List all SwiftVersion records with formatted output
    func listSwiftVersions() async throws {
        let records = try await queryRecords(recordType: "SwiftVersion")

        print("\n🔶 Swift Versions (\(records.count) total)")
        print(String(repeating: "=", count: 80))

        if records.isEmpty {
            print("   No Swift versions found.")
            return
        }

        for record in records.sorted(by: {
            ($0.fields["version"]?.stringValue ?? "") > ($1.fields["version"]?.stringValue ?? "")
        }) {
            printSwiftVersionRecord(record)
        }
    }

    /// List all records across all types with summary
    func listAllRecords() async throws {
        try await listRestoreImages()
        try await listXcodeVersions()
        try await listSwiftVersions()

        // Print summary
        let restoreCount = try await queryRecords(recordType: "RestoreImage").count
        let xcodeCount = try await queryRecords(recordType: "XcodeVersion").count
        let swiftCount = try await queryRecords(recordType: "SwiftVersion").count
        let total = restoreCount + xcodeCount + swiftCount

        print("\n📊 Summary")
        print(String(repeating: "=", count: 80))
        print("  Total Records: \(total)")
        print("    • Restore Images: \(restoreCount)")
        print("    • Xcode Versions: \(xcodeCount)")
        print("    • Swift Versions: \(swiftCount)")
        print("")
    }

    // MARK: - Private Formatting Helpers

    private func printRestoreImageRecord(_ record: RecordInfo) {
        let build = record.fields["buildNumber"]?.stringValue ?? "Unknown"
        let signed = record.fields["isSigned"]?.boolValue ?? false
        let prerelease = record.fields["isPrerelease"]?.boolValue ?? false
        let source = record.fields["source"]?.stringValue ?? "Unknown"
        let size = record.fields["fileSize"]?.intValue ?? 0

        let signedStr = signed ? "✅ Signed" : "❌ Unsigned"
        let prereleaseStr = prerelease ? "[Beta/RC]" : ""
        let sizeStr = formatFileSize(size)

        print("    \(build) \(prereleaseStr)")
        print("      \(signedStr) | Size: \(sizeStr) | Source: \(source)")
    }

    private func printXcodeVersionRecord(_ record: RecordInfo) {
        let version = record.fields["version"]?.stringValue ?? "Unknown"
        let build = record.fields["buildNumber"]?.stringValue ?? "Unknown"
        let releaseDate = record.fields["releaseDate"]?.dateValue
        let size = record.fields["fileSize"]?.intValue ?? 0

        let dateStr = releaseDate.map { formatDate($0) } ?? "Unknown"
        let sizeStr = formatFileSize(size)

        print("\n  \(version) (Build \(build))")
        print("    Released: \(dateStr) | Size: \(sizeStr)")
    }

    private func printSwiftVersionRecord(_ record: RecordInfo) {
        let version = record.fields["version"]?.stringValue ?? "Unknown"
        let releaseDate = record.fields["releaseDate"]?.dateValue

        let dateStr = releaseDate.map { formatDate($0) } ?? "Unknown"

        print("\n  Swift \(version)")
        print("    Released: \(dateStr)")
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    private func formatFileSize(_ bytes: Int) -> String {
        let gb = Double(bytes) / 1_000_000_000
        if gb >= 1.0 {
            return String(format: "%.2f GB", gb)
        } else {
            let mb = Double(bytes) / 1_000_000
            return String(format: "%.0f MB", mb)
        }
    }
}
