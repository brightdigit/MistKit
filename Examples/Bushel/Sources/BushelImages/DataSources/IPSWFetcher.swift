import Foundation
import IPSWDownloads
import OpenAPIURLSession
import OSVer

/// Fetcher for macOS restore images using the IPSWDownloads package
struct IPSWFetcher: DataSourceFetcher, Sendable {
    typealias Record = [RestoreImageRecord]
    /// Fetch all VirtualMac2,1 restore images from ipsw.me
    func fetch() async throws -> [RestoreImageRecord] {
        // Fetch Last-Modified header to know when ipsw.me data was updated
        let ipswURL = URL(string: "https://api.ipsw.me/v4/device/VirtualMac2,1?type=ipsw")!
        let lastModified = await HTTPHeaderHelpers.fetchLastModified(from: ipswURL)

        // Create IPSWDownloads client with URLSession transport
        let client = IPSWDownloads(
            transport: URLSessionTransport()
        )

        // Fetch device firmware data for VirtualMac2,1 (macOS virtual machines)
        let device = try await client.device(
            withIdentifier: "VirtualMac2,1",
            type: .ipsw
        )

        return device.firmwares.map { firmware in
            RestoreImageRecord(
                version: firmware.version.description, // OSVer -> String
                buildNumber: firmware.buildid,
                releaseDate: firmware.releasedate,
                downloadURL: firmware.url.absoluteString,
                fileSize: firmware.filesize,
                sha256Hash: "", // Not provided by ipsw.me; backfilled from AppleDB during merge
                sha1Hash: firmware.sha1sum?.hexString ?? "",
                isSigned: firmware.signed,
                isPrerelease: false, // ipsw.me doesn't include beta releases
                source: "ipsw.me",
                notes: nil,
                sourceUpdatedAt: lastModified // When ipsw.me last updated their database
            )
        }
    }
}

// MARK: - Data Extension

private extension Data {
    /// Convert Data to hexadecimal string
    var hexString: String {
        map { String(format: "%02x", $0) }.joined()
    }
}
