//
//  MESUFetcher.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

public import BushelFoundation
import BushelUtilities
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for Apple MESU (Mobile Equipment Software Update) manifest
/// Used for freshness detection of the latest signed restore image
public struct MESUFetcher: DataSourceFetcher, Sendable {
  public typealias Record = RestoreImageRecord?

  // MARK: - Error Types

  internal enum FetchError: Error {
    case invalidURL
    case parsingFailed
  }

  // MARK: - Initializers

  public init() {}

  // MARK: - Public Methods

  /// Fetch the latest signed restore image from Apple's MESU service
  public func fetch() async throws -> RestoreImageRecord? {
    let urlString =
      "https://mesu.apple.com/assets/macos/com_apple_macOSIPSW/com_apple_macOSIPSW.xml"
    guard let url = URL(string: urlString) else {
      throw FetchError.invalidURL
    }

    // Fetch Last-Modified header to know when MESU was last updated
    let lastModified = await URLSession.shared.fetchLastModified(from: url)

    let (data, _) = try await URLSession.shared.data(from: url)

    // Parse as property list (plist)
    guard
      let plist = try PropertyListSerialization.propertyList(from: data, format: nil)
        as? [String: Any]
    else {
      throw FetchError.parsingFailed
    }

    // Navigate to the firmware data
    // Structure: MobileDeviceSoftwareVersionsByVersion -> "1" ->
    // MobileDeviceSoftwareVersions -> VirtualMac2,1 -> BuildVersion -> Restore
    guard let versionsByVersion = plist["MobileDeviceSoftwareVersionsByVersion"] as? [String: Any],
      let version1 = versionsByVersion["1"] as? [String: Any],
      let softwareVersions = version1["MobileDeviceSoftwareVersions"] as? [String: Any],
      let virtualMac = softwareVersions["VirtualMac2,1"] as? [String: Any]
    else {
      return nil
    }

    // Find the first available build (should be the latest signed)
    for (buildVersion, buildInfo) in virtualMac {
      guard let buildInfo = buildInfo as? [String: Any],
        let restoreDict = buildInfo["Restore"] as? [String: Any],
        let productVersion = restoreDict["ProductVersion"] as? String,
        let firmwareURL = restoreDict["FirmwareURL"] as? String
      else {
        continue
      }

      let firmwareSHA1 = restoreDict["FirmwareSHA1"] as? String ?? ""

      // Return the first restore image found (typically the latest)
      guard let downloadURL = URL(string: firmwareURL) else {
        continue  // Skip if URL is invalid
      }

      return RestoreImageRecord(
        version: productVersion,
        buildNumber: buildVersion,
        releaseDate: Date(),  // MESU doesn't provide release date, use current date
        downloadURL: downloadURL,
        fileSize: 0,  // Not provided by MESU
        sha256Hash: "",  // MESU only provides SHA1
        sha1Hash: firmwareSHA1,
        isSigned: true,  // MESU only lists currently signed images
        isPrerelease: false,  // MESU typically only has final releases
        source: "mesu.apple.com",
        notes: "Latest signed release from Apple MESU",
        sourceUpdatedAt: lastModified  // When Apple last updated MESU manifest
      )
    }

    // No restore images found in the plist
    return nil
  }
}
