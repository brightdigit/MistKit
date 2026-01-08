import Foundation

/// Fetcher for Xcode releases from xcodereleases.com JSON API
struct XcodeReleasesFetcher: DataSourceFetcher, Sendable {
    typealias Record = [XcodeVersionRecord]
    // MARK: - API Models

    private struct XcodeRelease: Codable {
        let checksums: Checksums?
        let compilers: Compilers?
        let date: ReleaseDate
        let links: Links?
        let name: String
        let requires: String
        let sdks: SDKs?
        let version: Version

        struct Checksums: Codable {
            let sha1: String
        }

        struct Compilers: Codable {
            let clang: [Compiler]?
            let swift: [Compiler]?
        }

        struct Compiler: Codable {
            let build: String?
            let number: String?
            let release: Release?
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
                return Calendar.current.date(from: components) ?? Date()
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
                let build: String?
                let number: String?
                let release: Release?
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
            // Build SDK versions JSON (if SDK info is available)
            var sdkDict: [String: String] = [:]
            if let sdks = release.sdks {
                if let ios = sdks.iOS?.first, let number = ios.number { sdkDict["iOS"] = number }
                if let macos = sdks.macOS?.first, let number = macos.number { sdkDict["macOS"] = number }
                if let tvos = sdks.tvOS?.first, let number = tvos.number { sdkDict["tvOS"] = number }
                if let visionos = sdks.visionOS?.first, let number = visionos.number { sdkDict["visionOS"] = number }
                if let watchos = sdks.watchOS?.first, let number = watchos.number { sdkDict["watchOS"] = number }
            }

            // Encode SDK dictionary to JSON string with proper error handling
            let sdkString: String? = {
                do {
                    let data = try JSONEncoder().encode(sdkDict)
                    return String(data: data, encoding: .utf8)
                } catch {
                    BushelLogger.warning(
                        "Failed to encode SDK versions for \(release.name): \(error)",
                        subsystem: BushelLogger.dataSource
                    )
                    return nil
                }
            }()

            // Extract Swift version (if compilers info is available)
            let swiftVersion = release.compilers?.swift?.first?.number

            // Store requires string temporarily for later resolution
            // Format: "REQUIRES:<version string>|NOTES_URL:<url>"
            var notesField = "REQUIRES:\(release.requires)"
            if let notesURL = release.links?.notes?.url {
                notesField += "|NOTES_URL:\(notesURL)"
            }

            return XcodeVersionRecord(
                version: release.version.number,
                buildNumber: release.version.build,
                releaseDate: release.date.toDate,
                downloadURL: release.links?.download?.url,
                fileSize: nil, // Not provided by API
                isPrerelease: release.version.release.isPrerelease,
                minimumMacOS: nil, // Will be resolved in DataSourcePipeline
                includedSwiftVersion: swiftVersion.map { "SwiftVersion-\($0)" },
                sdkVersions: sdkString,
                notes: notesField
            )
        }
    }

}
