import Foundation

/// Fetcher for macOS restore images using TheAppleWiki.com
struct TheAppleWikiFetcher: Sendable {
    /// Fetch all macOS restore images from TheAppleWiki
    func fetch() async throws -> [RestoreImageRecord] {
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
                    isSigned: false, // Unknown - will be merged from other sources
                    isPrerelease: version.isPrerelease,
                    source: "theapplewiki.com",
                    notes: "Device: \(version.deviceModel)"
                )
            }
    }
}
