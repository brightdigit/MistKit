import Foundation
import SwiftSoup

/// Fetcher for macOS beta/RC restore images from Mr. Macintosh database
struct MrMacintoshFetcher: Sendable {
    // MARK: - Public API

    /// Fetch beta and RC restore images from Mr. Macintosh
    func fetch() async throws -> [RestoreImageRecord] {
        let urlString = "https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/"
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        guard let html = String(data: data, encoding: .utf8) else {
            throw FetchError.invalidEncoding
        }

        let doc = try SwiftSoup.parse(html)

        // Find the main table - may need adjustment based on actual HTML structure
        // This is a placeholder implementation that would need to be refined
        // based on the actual HTML structure of the page
        let rows = try doc.select("table tr")

        var records: [RestoreImageRecord] = []

        for row in rows {
            let cells = try row.select("td")
            guard cells.count >= 5 else { continue }

            // Expected columns (adjust based on actual page structure):
            // Version | Build | Date | Download Link | Signed Status
            let version = try cells[0].text()
            let buildNumber = try cells[1].text()
            let dateStr = try cells[2].text()
            let downloadLink = try cells[3].select("a").attr("href")
            let signedStatus = try cells[4].text()

            // Skip if this doesn't look like a valid row
            guard !version.isEmpty, !buildNumber.isEmpty else {
                continue
            }

            // Determine if it's a beta/RC release
            let isPrerelease = version.lowercased().contains("beta") ||
                              version.lowercased().contains("rc")

            // Parse date (format varies: "MM/DD/YY" or "MM/DD")
            let releaseDate = parseDate(from: dateStr) ?? Date()

            // Check if signed
            let isSigned = signedStatus.uppercased().contains("YES")

            records.append(RestoreImageRecord(
                version: version,
                buildNumber: buildNumber,
                releaseDate: releaseDate,
                downloadURL: downloadLink,
                fileSize: 0, // Not provided
                sha256Hash: "", // Not provided
                sha1Hash: "", // Not provided
                isSigned: isSigned,
                isPrerelease: isPrerelease,
                source: "mrmacintosh.com",
                notes: nil
            ))
        }

        return records
    }

    // MARK: - Helpers

    /// Parse date from Mr. Macintosh format (MM/DD/YY or MM/DD)
    private func parseDate(from string: String) -> Date? {
        let formatters = [
            makeDateFormatter(format: "MM/dd/yy"),
            makeDateFormatter(format: "MM/dd/yyyy"),
            makeDateFormatter(format: "MM/dd")
        ]

        for formatter in formatters {
            if let date = formatter.date(from: string) {
                return date
            }
        }

        return nil
    }

    private func makeDateFormatter(format: String) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }

    // MARK: - Error Types

    enum FetchError: Error {
        case invalidURL
        case invalidEncoding
    }
}
