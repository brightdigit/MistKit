import Foundation

/// Fetcher for Xcode releases from xcodereleases.com JSON API
struct XcodeReleasesFetcher: Sendable {
    // MARK: - API Models

    private struct XcodeRelease: Codable {
        let checksums: Checksums?
        let compilers: Compilers
        let date: ReleaseDate
        let links: Links
        let name: String
        let requires: String
        let sdks: SDKs
        let version: Version

        struct Checksums: Codable {
            let sha1: String
        }

        struct Compilers: Codable {
            let clang: [Compiler]
            let swift: [Compiler]
        }

        struct Compiler: Codable {
            let build: String
            let number: String
            let release: Release
        }

        struct Release: Codable {
            let release: Bool?
            let beta: Int?
            let rc: Int?

            var isPrerelease: Bool {
                beta != nil || rc != nil
            }
        }

        struct ReleaseDate: Codable {
            let day: Int
            let month: Int
            let year: Int

            var toDate: Date {
                let components = DateComponents(year: year, month: month, day: day)
                return Calendar.current.date(from: components)!
            }
        }

        struct Links: Codable {
            let download: Download?
            let notes: Notes?

            struct Download: Codable {
                let url: String
            }

            struct Notes: Codable {
                let url: String
            }
        }

        struct SDKs: Codable {
            let iOS: [SDK]?
            let macOS: [SDK]?
            let tvOS: [SDK]?
            let visionOS: [SDK]?
            let watchOS: [SDK]?

            struct SDK: Codable {
                let build: String
                let number: String
                let release: Release
            }
        }

        struct Version: Codable {
            let build: String
            let number: String
            let release: Release
        }
    }

    // MARK: - Public API

    /// Fetch all Xcode releases from xcodereleases.com
    func fetch() async throws -> [XcodeVersionRecord] {
        let url = URL(string: "https://xcodereleases.com/data.json")!
        let (data, _) = try await URLSession.shared.data(from: url)
        let releases = try JSONDecoder().decode([XcodeRelease].self, from: data)

        return releases.map { release in
            // Build SDK versions JSON
            var sdkDict: [String: String] = [:]
            if let ios = release.sdks.iOS?.first { sdkDict["iOS"] = ios.number }
            if let macos = release.sdks.macOS?.first { sdkDict["macOS"] = macos.number }
            if let tvos = release.sdks.tvOS?.first { sdkDict["tvOS"] = tvos.number }
            if let visionos = release.sdks.visionOS?.first { sdkDict["visionOS"] = visionos.number }
            if let watchos = release.sdks.watchOS?.first { sdkDict["watchOS"] = watchos.number }

            let sdkJSON = try? JSONEncoder().encode(sdkDict)
            let sdkString = sdkJSON.flatMap { String(data: $0, encoding: .utf8) }

            // Extract Swift version
            let swiftVersion = release.compilers.swift.first?.number

            return XcodeVersionRecord(
                version: release.version.number,
                buildNumber: release.version.build,
                releaseDate: release.date.toDate,
                downloadURL: release.links.download?.url,
                fileSize: nil, // Not provided by API
                isPrerelease: release.version.release.isPrerelease,
                minimumMacOS: minimumMacOSReference(from: release.requires),
                includedSwiftVersion: swiftVersion.map { "SwiftVersion-\($0)" },
                sdkVersions: sdkString,
                notes: release.links.notes?.url
            )
        }
    }

    // MARK: - Helpers

    /// Convert minimum macOS version string to RestoreImage record reference
    private func minimumMacOSReference(from versionString: String) -> String? {
        // For now, we'll store the version string and resolve it later
        // during sync when we have all RestoreImage records
        // Format: "RestoreImage-<buildNumber>" will be resolved by SyncEngine
        // Return nil for now as we don't have build numbers from version strings
        nil
    }
}
