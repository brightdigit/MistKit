import Foundation

/// Fetcher for Apple MESU (Mobile Equipment Software Update) manifest
/// Used for freshness detection of the latest signed restore image
struct MESUFetcher: Sendable {
    // MARK: - Internal Models

    fileprivate struct MESUAsset: Codable {
        let BuildVersion: String
        let ProductVersion: String
        let FirmwareURL: String
        let FirmwareSHA1: String
    }

    // MARK: - Public API

    /// Fetch the latest signed restore image from Apple's MESU service
    func fetch() async throws -> RestoreImageRecord? {
        let urlString = "https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml"
        guard let url = URL(string: urlString) else {
            throw FetchError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        // Parse XML
        let parser = XMLParser(data: data)
        let delegate = MESUXMLParserDelegate()
        parser.delegate = delegate

        guard parser.parse(), let asset = delegate.asset else {
            throw FetchError.parsingFailed
        }

        return RestoreImageRecord(
            version: asset.ProductVersion,
            buildNumber: asset.BuildVersion,
            releaseDate: Date(), // MESU doesn't provide release date, use current date
            downloadURL: asset.FirmwareURL,
            fileSize: 0, // Not provided by MESU
            sha256Hash: "", // MESU only provides SHA1
            sha1Hash: asset.FirmwareSHA1,
            isSigned: true, // MESU only lists currently signed images
            isPrerelease: false, // MESU typically only has final releases
            source: "mesu.apple.com",
            notes: "Latest signed release from Apple MESU"
        )
    }

    // MARK: - Error Types

    enum FetchError: Error {
        case invalidURL
        case parsingFailed
    }
}

// MARK: - XML Parser Delegate

private final class MESUXMLParserDelegate: NSObject, XMLParserDelegate, @unchecked Sendable {
    var asset: MESUFetcher.MESUAsset?
    private var currentElement: String = ""
    private var currentBuildVersion: String = ""
    private var currentProductVersion: String = ""
    private var currentFirmwareURL: String = ""
    private var currentFirmwareSHA1: String = ""

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        currentElement = elementName
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        switch currentElement {
        case "BuildVersion":
            currentBuildVersion += trimmed
        case "ProductVersion":
            currentProductVersion += trimmed
        case "FirmwareURL":
            currentFirmwareURL += trimmed
        case "FirmwareSHA1":
            currentFirmwareSHA1 += trimmed
        default:
            break
        }
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        if elementName == "Asset" {
            // Create asset from accumulated data
            if !currentBuildVersion.isEmpty && !currentProductVersion.isEmpty {
                asset = MESUFetcher.MESUAsset(
                    BuildVersion: currentBuildVersion,
                    ProductVersion: currentProductVersion,
                    FirmwareURL: currentFirmwareURL,
                    FirmwareSHA1: currentFirmwareSHA1
                )
            }

            // Reset for next asset (though MESU typically has only one)
            currentBuildVersion = ""
            currentProductVersion = ""
            currentFirmwareURL = ""
            currentFirmwareSHA1 = ""
        }
        currentElement = ""
    }
}
