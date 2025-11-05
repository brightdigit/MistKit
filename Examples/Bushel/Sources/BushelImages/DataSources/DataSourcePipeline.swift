import Foundation

/// Orchestrates fetching data from all sources with deduplication and relationship resolution
struct DataSourcePipeline: Sendable {
    // MARK: - Configuration

    struct Options: Sendable {
        var includeRestoreImages: Bool = true
        var includeXcodeVersions: Bool = true
        var includeSwiftVersions: Bool = true
        var includeBetaReleases: Bool = true
        var includeTheAppleWiki: Bool = true
    }

    // MARK: - Results

    struct FetchResult: Sendable {
        var restoreImages: [RestoreImageRecord]
        var xcodeVersions: [XcodeVersionRecord]
        var swiftVersions: [SwiftVersionRecord]
    }

    // MARK: - Public API

    /// Fetch all data from configured sources
    func fetch(options: Options = Options()) async throws -> FetchResult {
        var restoreImages: [RestoreImageRecord] = []
        var xcodeVersions: [XcodeVersionRecord] = []
        var swiftVersions: [SwiftVersionRecord] = []

        do {
            restoreImages = try await fetchRestoreImages(options: options)
        } catch {
            print("⚠️  Restore images fetch failed: \(error)")
            throw error
        }

        do {
            xcodeVersions = try await fetchXcodeVersions(options: options)
        } catch {
            print("⚠️  Xcode versions fetch failed: \(error)")
            throw error
        }

        do {
            swiftVersions = try await fetchSwiftVersions(options: options)
        } catch {
            print("⚠️  Swift versions fetch failed: \(error)")
            throw error
        }

        return FetchResult(
            restoreImages: restoreImages,
            xcodeVersions: xcodeVersions,
            swiftVersions: swiftVersions
        )
    }

    // MARK: - Private Fetching Methods

    private func fetchRestoreImages(options: Options) async throws -> [RestoreImageRecord] {
        guard options.includeRestoreImages else {
            return []
        }

        var allImages: [RestoreImageRecord] = []

        // Fetch from ipsw.me
        do {
            let ipswImages = try await IPSWFetcher().fetch()
            allImages.append(contentsOf: ipswImages)
            print("   ✓ ipsw.me: \(ipswImages.count) images")
        } catch {
            print("   ⚠️  ipsw.me failed: \(error)")
            throw error
        }

        // Fetch from MESU
        do {
            if let mesuImage = try await MESUFetcher().fetch() {
                allImages.append(mesuImage)
                print("   ✓ MESU: 1 image")
            }
        } catch {
            print("   ⚠️  MESU failed: \(error)")
            throw error
        }

        // Fetch from Mr. Macintosh (betas)
        if options.includeBetaReleases {
            do {
                let mrMacImages = try await MrMacintoshFetcher().fetch()
                allImages.append(contentsOf: mrMacImages)
                print("   ✓ Mr. Macintosh: \(mrMacImages.count) images")
            } catch {
                print("   ⚠️  Mr. Macintosh failed: \(error)")
                throw error
            }
        }

        // Fetch from TheAppleWiki
        if options.includeTheAppleWiki {
            do {
                let wikiImages = try await TheAppleWikiFetcher().fetch()
                allImages.append(contentsOf: wikiImages)
                print("   ✓ TheAppleWiki: \(wikiImages.count) images")
            } catch {
                print("   ⚠️  TheAppleWiki failed: \(error)")
                throw error
            }
        }

        // Deduplicate by build number (keep first occurrence)
        return deduplicateRestoreImages(allImages)
    }

    private func fetchXcodeVersions(options: Options) async throws -> [XcodeVersionRecord] {
        guard options.includeXcodeVersions else {
            return []
        }

        let versions = try await XcodeReleasesFetcher().fetch()
        return deduplicateXcodeVersions(versions)
    }

    private func fetchSwiftVersions(options: Options) async throws -> [SwiftVersionRecord] {
        guard options.includeSwiftVersions else {
            return []
        }

        let versions = try await SwiftVersionFetcher().fetch()
        return deduplicateSwiftVersions(versions)
    }

    // MARK: - Deduplication

    /// Deduplicate restore images by build number, keeping the most complete record
    private func deduplicateRestoreImages(_ images: [RestoreImageRecord]) -> [RestoreImageRecord] {
        var uniqueImages: [String: RestoreImageRecord] = [:]

        for image in images {
            let key = image.buildNumber

            if let existing = uniqueImages[key] {
                // Keep the record with more complete data
                uniqueImages[key] = mergeRestoreImages(existing, image)
            } else {
                uniqueImages[key] = image
            }
        }

        return Array(uniqueImages.values).sorted { $0.releaseDate > $1.releaseDate }
    }

    /// Merge two restore image records, preferring non-empty values
    private func mergeRestoreImages(
        _ first: RestoreImageRecord,
        _ second: RestoreImageRecord
    ) -> RestoreImageRecord {
        var merged = first

        // Prefer non-empty/non-zero values from second
        if !second.sha256Hash.isEmpty && first.sha256Hash.isEmpty {
            merged.sha256Hash = second.sha256Hash
        }
        if !second.sha1Hash.isEmpty && first.sha1Hash.isEmpty {
            merged.sha1Hash = second.sha1Hash
        }
        if second.fileSize > 0 && first.fileSize == 0 {
            merged.fileSize = second.fileSize
        }

        // Combine notes
        if let secondNotes = second.notes, !secondNotes.isEmpty {
            if let firstNotes = first.notes, !firstNotes.isEmpty {
                merged.notes = "\(firstNotes); \(secondNotes)"
            } else {
                merged.notes = secondNotes
            }
        }

        return merged
    }

    /// Deduplicate Xcode versions by build number
    private func deduplicateXcodeVersions(_ versions: [XcodeVersionRecord]) -> [XcodeVersionRecord] {
        var uniqueVersions: [String: XcodeVersionRecord] = [:]

        for version in versions {
            let key = version.buildNumber
            if uniqueVersions[key] == nil {
                uniqueVersions[key] = version
            }
        }

        return Array(uniqueVersions.values).sorted { $0.releaseDate > $1.releaseDate }
    }

    /// Deduplicate Swift versions by version number
    private func deduplicateSwiftVersions(_ versions: [SwiftVersionRecord]) -> [SwiftVersionRecord] {
        var uniqueVersions: [String: SwiftVersionRecord] = [:]

        for version in versions {
            let key = version.version
            if uniqueVersions[key] == nil {
                uniqueVersions[key] = version
            }
        }

        return Array(uniqueVersions.values).sorted { $0.releaseDate > $1.releaseDate }
    }
}
