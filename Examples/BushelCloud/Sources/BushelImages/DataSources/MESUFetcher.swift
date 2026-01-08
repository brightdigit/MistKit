import Foundation

/// Fetcher for Apple MESU (Mobile Equipment Software Update) manifest
/// Used for freshness detection of the latest signed restore image
struct MESUFetcher: DataSourceFetcher, Sendable {
    typealias Record = RestoreImageRecord?
    // MARK: - Internal Models

    fileprivate struct RestoreInfo: Codable {
        let BuildVersion: String
        let ProductVersion: String
        let FirmwareURL: String
        let FirmwareSHA1: String?
    }

    // MARK: - Public API

    /// Fetch the latest signed restore image from Apple's MESU service
    func fetch() async throws -> RestoreImageRecord? {
        let urlString = "https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml"
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL
        }

        // Fetch Last-Modified header to know when MESU was last updated
        let lastModified = await HTTPHeaderHelpers.fetchLastModified(from: url)

        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse as property list (plist)
        guard let plist = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any] else {
            throw FetchError.parsingFailed
        }

        // Navigate to the firmware data
        // Structure: MobileDeviceSoftwareVersionsByVersion -> "1" -> MobileDeviceSoftwareVersions -> VirtualMac2,1 -> BuildVersion -> Restore
        guard let versionsByVersion = plist["MobileDeviceSoftwareVersionsByVersion"] as? [String: Any],
              let version1 = versionsByVersion["1"] as? [String: Any],
              let softwareVersions = version1["MobileDeviceSoftwareVersions"] as? [String: Any],
              let virtualMac = softwareVersions["VirtualMac2,1"] as? [String: Any] else {
            return nil
        }

        // Find the first available build (should be the latest signed)
        for (buildVersion, buildInfo) in virtualMac {
            guard let buildInfo = buildInfo as? [String: Any],
                  let restoreDict = buildInfo["Restore"] as? [String: Any],
                  let productVersion = restoreDict["ProductVersion"] as? String,
                  let firmwareURL = restoreDict["FirmwareURL"] as? String else {
                continue
            }

            let firmwareSHA1 = restoreDict["FirmwareSHA1"] as? String ?? ""

            // Return the first restore image found (typically the latest)
            return RestoreImageRecord(
                version: productVersion,
                buildNumber: buildVersion,
                releaseDate: Date(), // MESU doesn't provide release date, use current date
                downloadURL: firmwareURL,
                fileSize: 0, // Not provided by MESU
                sha256Hash: "", // MESU only provides SHA1
                sha1Hash: firmwareSHA1,
                isSigned: true, // MESU only lists currently signed images
                isPrerelease: false, // MESU typically only has final releases
                source: "mesu.apple.com",
                notes: "Latest signed release from Apple MESU",
                sourceUpdatedAt: lastModified // When Apple last updated MESU manifest
            )
        }

        // No restore images found in the plist
        return nil
    }

    // MARK: - Error Types

    enum FetchError: Error {
        case invalidURL
        case parsingFailed
    }
}
