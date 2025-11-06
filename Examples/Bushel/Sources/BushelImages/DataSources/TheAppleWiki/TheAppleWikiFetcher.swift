import Foundation

/// Fetcher for macOS restore images using TheAppleWiki.com
@available(*, deprecated, message: "Use AppleDBFetcher instead for more reliable and up-to-date data")
internal struct TheAppleWikiFetcher: DataSourceFetcher, Sendable {
    internal typealias Record = [RestoreImageRecord]
    /// Fetch all macOS restore images from TheAppleWiki
    internal func fetch() async throws -> [RestoreImageRecord] {
        // Fetch Last-Modified header from TheAppleWiki API
        let apiURL = URL(string: "https://theapplewiki.com/api.php?action=parse&page=Firmware/Mac&format=json")!
        let lastModified = await HTTPHeaderHelpers.fetchLastModified(from: apiURL)

        let parser = IPSWParser()

        // Fetch all versions without device filtering (UniversalMac images work for all devices)
        let versions = try await parser.fetchAllIPSWVersions(deviceFilter: nil)

        // Map to RestoreImageRecord, filtering out only invalid entries
        // Deduplication happens later in DataSourcePipeline
        return versions
            .filter { $0.isValid }
            .compactMap { version -> RestoreImageRecord? in
                // Skip if we can't get essential data
                guard let downloadURL = version.url?.absoluteString,
                      let fileSize = version.fileSizeInBytes else {
                    return nil
                }

                // Use current date as fallback if release date is missing
                let releaseDate = version.releaseDate ?? Date()

                return RestoreImageRecord(
                    version: version.version,
                    buildNumber: version.buildNumber,
                    releaseDate: releaseDate,
                    downloadURL: downloadURL,
                    fileSize: fileSize,
                    sha256Hash: "", // Not available from TheAppleWiki
                    sha1Hash: version.sha1,
                    isSigned: nil, // Unknown - will be merged from other sources
                    isPrerelease: version.isPrerelease,
                    source: "theapplewiki.com",
                    notes: "Device: \(version.deviceModel)",
                    sourceUpdatedAt: lastModified // When TheAppleWiki API was last updated
                )
            }
    }
}
