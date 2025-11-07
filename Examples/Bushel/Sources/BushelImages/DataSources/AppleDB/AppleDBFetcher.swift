import Foundation

/// Fetcher for macOS restore images using AppleDB API
struct AppleDBFetcher: DataSourceFetcher, Sendable {
    typealias Record = [RestoreImageRecord]
    private let deviceIdentifier = "VirtualMac2,1"

    /// Fetch all VirtualMac2,1 restore images from AppleDB
    func fetch() async throws -> [RestoreImageRecord] {
        // Fetch when macOS data was last updated using GitHub API
        let sourceUpdatedAt = await Self.fetchGitHubLastCommitDate()

        // Fetch AppleDB data
        let entries = try await Self.fetchAppleDBData()

        // Filter for VirtualMac2,1 and map to RestoreImageRecord
        return entries
            .filter { $0.deviceMap.contains(deviceIdentifier) }
            .compactMap { entry in
                Self.mapToRestoreImage(entry: entry, sourceUpdatedAt: sourceUpdatedAt, deviceIdentifier: deviceIdentifier)
            }
    }

    // MARK: - Private Methods

    /// Fetch the last commit date for macOS data from GitHub API
    private static func fetchGitHubLastCommitDate() async -> Date? {
        do {
            let url = URL(string: "https://api.github.com/repos/littlebyteorg/appledb/commits?path=osFiles/macOS&per_page=1")!

            let (data, _) = try await URLSession.shared.data(from: url)

            let commits = try JSONDecoder().decode([GitHubCommitsResponse].self, from: data)

            guard let firstCommit = commits.first else {
                BushelLogger.warning("No commits found in AppleDB GitHub repository", subsystem: BushelLogger.dataSource)
                return nil
            }

            // Parse ISO 8601 date
            let isoFormatter = ISO8601DateFormatter()
            guard let date = isoFormatter.date(from: firstCommit.commit.committer.date) else {
                BushelLogger.warning("Failed to parse commit date: \(firstCommit.commit.committer.date)", subsystem: BushelLogger.dataSource)
                return nil
            }

            BushelLogger.verbose("AppleDB macOS data last updated: \(date) (commit: \(firstCommit.sha.prefix(7)))", subsystem: BushelLogger.dataSource)
            return date

        } catch {
            BushelLogger.warning("Failed to fetch GitHub commit date for AppleDB: \(error)", subsystem: BushelLogger.dataSource)
            // Fallback to HTTP Last-Modified header
            let appleDBURL = URL(string: "https://api.appledb.dev/ios/macOS/main.json")!
            return await HTTPHeaderHelpers.fetchLastModified(from: appleDBURL)
        }
    }

    /// Fetch macOS data from AppleDB API
    private static func fetchAppleDBData() async throws -> [AppleDBEntry] {
        let url = URL(string: "https://api.appledb.dev/ios/macOS/main.json")!

        BushelLogger.verbose("Fetching AppleDB data from \(url)", subsystem: BushelLogger.dataSource)

        let (data, _) = try await URLSession.shared.data(from: url)

        let entries = try JSONDecoder().decode([AppleDBEntry].self, from: data)

        BushelLogger.verbose("Fetched \(entries.count) total entries from AppleDB", subsystem: BushelLogger.dataSource)

        return entries
    }

    /// Map an AppleDB entry to RestoreImageRecord
    private static func mapToRestoreImage(entry: AppleDBEntry, sourceUpdatedAt: Date?, deviceIdentifier: String) -> RestoreImageRecord? {
        // Skip entries without a build number (required for unique identification)
        guard let build = entry.build else {
            BushelLogger.verbose("Skipping AppleDB entry without build number: \(entry.version)", subsystem: BushelLogger.dataSource)
            return nil
        }

        // Determine if signed for VirtualMac2,1
        let isSigned = entry.signed.isSigned(for: deviceIdentifier)

        // Determine if prerelease
        let isPrerelease = entry.beta == true || entry.rc == true || entry.internal == true

        // Parse release date if available
        let releaseDate: Date?
        if !entry.released.isEmpty {
            let isoFormatter = ISO8601DateFormatter()
            releaseDate = isoFormatter.date(from: entry.released)
        } else {
            releaseDate = nil
        }

        // Find IPSW source
        guard let ipswSource = entry.sources?.first(where: { $0.type == "ipsw" }) else {
            BushelLogger.verbose("No IPSW source found for build \(build)", subsystem: BushelLogger.dataSource)
            return nil
        }

        // Get preferred or first active link
        guard let link = ipswSource.links?.first(where: { $0.preferred == true || $0.active == true }) else {
            BushelLogger.verbose("No active download link found for build \(build)", subsystem: BushelLogger.dataSource)
            return nil
        }

        return RestoreImageRecord(
            version: entry.version,
            buildNumber: build,
            releaseDate: releaseDate ?? Date(), // Fallback to current date
            downloadURL: link.url,
            fileSize: ipswSource.size ?? 0,
            sha256Hash: ipswSource.hashes?.sha2_256 ?? "",
            sha1Hash: ipswSource.hashes?.sha1 ?? "",
            isSigned: isSigned,
            isPrerelease: isPrerelease,
            source: "appledb.dev",
            notes: "Device-specific signing status from AppleDB",
            sourceUpdatedAt: sourceUpdatedAt
        )
    }
}

// MARK: - Error Types

extension AppleDBFetcher {
    enum FetchError: LocalizedError {
        case invalidURL
        case noDataFound
        case decodingFailed(Error)

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "Invalid AppleDB URL"
            case .noDataFound:
                return "No data found from AppleDB"
            case .decodingFailed(let error):
                return "Failed to decode AppleDB response: \(error.localizedDescription)"
            }
        }
    }
}
