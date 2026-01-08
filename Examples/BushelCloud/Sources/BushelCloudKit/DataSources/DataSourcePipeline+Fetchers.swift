//
//  DataSourcePipeline+Fetchers.swift
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
import Foundation

// MARK: - Private Fetching Methods
extension DataSourcePipeline {
  internal func fetchRestoreImages(options: Options) async throws -> [RestoreImageRecord] {
    guard options.includeRestoreImages else {
      return []
    }

    var allImages: [RestoreImageRecord] = []

    allImages.append(contentsOf: try await fetchIPSWImages(options: options))
    allImages.append(contentsOf: try await fetchMESUImages(options: options))
    allImages.append(contentsOf: try await fetchAppleDBImages(options: options))
    allImages.append(contentsOf: try await fetchMrMacintoshImages(options: options))
    allImages.append(contentsOf: try await fetchTheAppleWikiImages(options: options))

    allImages = try await enrichWithVirtualBuddy(allImages, options: options)

    // Deduplicate by build number (keep first occurrence)
    let preDedupeCount = allImages.count
    let deduped = deduplicateRestoreImages(allImages)
    ConsoleOutput.print("   📦 Deduplicated: \(preDedupeCount) → \(deduped.count) images")
    return deduped
  }

  private func fetchIPSWImages(options: Options) async throws -> [RestoreImageRecord] {
    do {
      let images = try await fetchWithMetadata(
        source: "ipsw.me",
        recordType: "RestoreImage",
        options: options
      ) {
        try await IPSWFetcher().fetch()
      }
      if !images.isEmpty {
        print("   ✓ ipsw.me: \(images.count) images")
      }
      return images
    } catch {
      print("   ⚠️  ipsw.me failed: \(error)")
      throw error
    }
  }

  private func fetchMESUImages(options: Options) async throws -> [RestoreImageRecord] {
    do {
      let images = try await fetchWithMetadata(
        source: "mesu.apple.com",
        recordType: "RestoreImage",
        options: options
      ) {
        if let image = try await MESUFetcher().fetch() {
          return [image]
        } else {
          return []
        }
      }
      if !images.isEmpty {
        print("   ✓ MESU: \(images.count) image")
      }
      return images
    } catch {
      print("   ⚠️  MESU failed: \(error)")
      throw error
    }
  }

  private func fetchAppleDBImages(options: Options) async throws -> [RestoreImageRecord] {
    guard options.includeAppleDB else {
      return []
    }

    do {
      let images = try await fetchWithMetadata(
        source: "appledb.dev",
        recordType: "RestoreImage",
        options: options
      ) {
        try await AppleDBFetcher().fetch()
      }
      if !images.isEmpty {
        print("   ✓ AppleDB: \(images.count) images")
      }
      return images
    } catch {
      print("   ⚠️  AppleDB failed: \(error)")
      // Don't throw - continue with other sources
      return []
    }
  }

  private func fetchMrMacintoshImages(options: Options) async throws -> [RestoreImageRecord] {
    guard options.includeBetaReleases else {
      return []
    }

    do {
      let images = try await fetchWithMetadata(
        source: "mrmacintosh.com",
        recordType: "RestoreImage",
        options: options
      ) {
        try await MrMacintoshFetcher().fetch()
      }
      if !images.isEmpty {
        print("   ✓ Mr. Macintosh: \(images.count) images")
      }
      return images
    } catch {
      print("   ⚠️  Mr. Macintosh failed: \(error)")
      throw error
    }
  }

  private func fetchTheAppleWikiImages(options: Options) async throws -> [RestoreImageRecord] {
    guard options.includeTheAppleWiki else {
      return []
    }

    do {
      let images = try await fetchWithMetadata(
        source: "theapplewiki.com",
        recordType: "RestoreImage",
        options: options
      ) {
        try await TheAppleWikiFetcher().fetch()
      }
      if !images.isEmpty {
        print("   ✓ TheAppleWiki: \(images.count) images")
      }
      return images
    } catch {
      print("   ⚠️  TheAppleWiki failed: \(error)")
      throw error
    }
  }

  private func enrichWithVirtualBuddy(
    _ images: [RestoreImageRecord],
    options: Options
  ) async throws -> [RestoreImageRecord] {
    guard options.includeVirtualBuddy else {
      return images
    }

    guard let fetcher = VirtualBuddyFetcher() else {
      print("   ⚠️  VirtualBuddy: No API key found (set VIRTUALBUDDY_API_KEY)")
      return images
    }

    do {
      let enrichableCount = images.filter { $0.downloadURL.scheme != "file" }.count
      let enrichedImages = try await fetcher.fetch(existingImages: images)
      print("   ✓ VirtualBuddy: Enriched \(enrichableCount) images with signing status")
      return enrichedImages
    } catch {
      print("   ⚠️  VirtualBuddy failed: \(error)")
      // Don't throw - continue with original data
      return images
    }
  }

  internal func fetchXcodeVersions(options: Options) async throws -> [XcodeVersionRecord] {
    guard options.includeXcodeVersions else {
      return []
    }

    let versions = try await fetchWithMetadata(
      source: "xcodereleases.com",
      recordType: "XcodeVersion",
      options: options
    ) {
      try await XcodeReleasesFetcher().fetch()
    }

    if !versions.isEmpty {
      print("   ✓ xcodereleases.com: \(versions.count) versions")
    }

    return deduplicateXcodeVersions(versions)
  }

  internal func fetchSwiftVersions(options: Options) async throws -> [SwiftVersionRecord] {
    guard options.includeSwiftVersions else {
      return []
    }

    let versions = try await fetchWithMetadata(
      source: "swiftversion.net",
      recordType: "SwiftVersion",
      options: options
    ) {
      try await SwiftVersionFetcher().fetch()
    }

    if !versions.isEmpty {
      print("   ✓ swiftversion.net: \(versions.count) versions")
    }

    return deduplicateSwiftVersions(versions)
  }
}
