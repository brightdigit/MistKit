import Foundation
import SwiftSoup

/// Fetcher for Swift compiler versions from swiftversion.net
struct SwiftVersionFetcher: DataSourceFetcher, Sendable {
    typealias Record = [SwiftVersionRecord]
    // MARK: - Internal Models

    private struct SwiftVersionEntry {
        let date: Date
        let swiftVersion: String
        let xcodeVersion: String
    }

    // MARK: - Public API

    /// Fetch all Swift versions from swiftversion.net
    func fetch() async throws -> [SwiftVersionRecord] {
        let url = URL(string: "https://swiftversion.net")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw FetchError.invalidEncoding
        }

        let doc = try SwiftSoup.parse(html)
        let rows = try doc.select("tbody tr.table-entry")

        var entries: [SwiftVersionEntry] = []
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd MMM yy"

        for row in rows {
            let cells = try row.select("td")
            guard cells.count == 3 else { continue }

            let dateStr = try cells[0].text()
            let swiftVer = try cells[1].text()
            let xcodeVer = try cells[2].text()

            guard let date = dateFormatter.date(from: dateStr) else {
                print("Warning: Could not parse date: \(dateStr)")
                continue
            }

            entries.append(SwiftVersionEntry(
                date: date,
                swiftVersion: swiftVer,
                xcodeVersion: xcodeVer
            ))
        }

        return entries.map { entry in
            SwiftVersionRecord(
                version: entry.swiftVersion,
                releaseDate: entry.date,
                downloadURL: "https://swift.org/download/", // Generic download page
                isPrerelease: entry.swiftVersion.contains("beta") ||
                             entry.swiftVersion.contains("snapshot"),
                notes: "Bundled with Xcode \(entry.xcodeVersion)"
            )
        }
    }

    // MARK: - Error Types

    enum FetchError: Error {
        case invalidEncoding
    }
}
