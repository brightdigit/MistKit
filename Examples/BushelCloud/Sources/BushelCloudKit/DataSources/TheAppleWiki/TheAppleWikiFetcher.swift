//
//  TheAppleWikiFetcher.swift
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

import BushelFoundation
import BushelUtilities
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for macOS restore images using TheAppleWiki.com
@available(
  *, deprecated, message: "Use AppleDBFetcher instead for more reliable and up-to-date data"
)
internal struct TheAppleWikiFetcher: DataSourceFetcher, Sendable {
  internal typealias Record = [RestoreImageRecord]
  /// Static base URL for TheAppleWiki API
  private static let wikiAPIURL: URL = {
    guard
      let url = URL(
        string: "https://theapplewiki.com/api.php?action=parse&page=Firmware/Mac&format=json"
      )
    else {
      fatalError("Invalid static URL for TheAppleWiki API - this should never happen")
    }
    return url
  }()

  /// Fetch all macOS restore images from TheAppleWiki
  internal func fetch() async throws -> [RestoreImageRecord] {
    // Fetch Last-Modified header from TheAppleWiki API
    let apiURL = Self.wikiAPIURL

    #if canImport(FoundationNetworking)
      // Use FoundationNetworking.URLSession directly on Linux
      let lastModified = await FoundationNetworking.URLSession.shared.fetchLastModified(
        from: apiURL
      )
    #else
      let lastModified = await URLSession.shared.fetchLastModified(from: apiURL)
    #endif

    let parser = IPSWParser()

    // Fetch all versions without device filtering (UniversalMac images work for all devices)
    let versions = try await parser.fetchAllIPSWVersions(deviceFilter: nil)

    // Map to RestoreImageRecord, filtering out only invalid entries
    // Deduplication happens later in DataSourcePipeline
    return
      versions
      .filter { $0.isValid }
      .compactMap { version -> RestoreImageRecord? in
        // Skip if we can't get essential data
        guard let downloadURL = version.url,
          let fileSize = version.fileSizeInBytes
        else {
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
          sha256Hash: "",  // Not available from TheAppleWiki
          sha1Hash: version.sha1,
          isSigned: nil,  // Unknown - will be merged from other sources
          isPrerelease: version.isPrerelease,
          source: "theapplewiki.com",
          notes: "Device: \(version.deviceModel)",
          sourceUpdatedAt: lastModified  // When TheAppleWiki API was last updated
        )
      }
  }
}
