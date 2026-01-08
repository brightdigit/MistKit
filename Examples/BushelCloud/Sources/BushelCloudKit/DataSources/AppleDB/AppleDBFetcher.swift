//
//  AppleDBFetcher.swift
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
public import BushelLogging
import BushelUtilities
import Foundation
import Logging

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for macOS restore images using AppleDB API
public struct AppleDBFetcher: DataSourceFetcher, Sendable {
  public typealias Record = [RestoreImageRecord]

  // MARK: - Type Properties

  // swiftlint:disable:next force_unwrapping
  private static let githubCommitsURL = URL(
    string:
      "https://api.github.com/repos/littlebyteorg/appledb/commits?path=osFiles/macOS&per_page=1"
  )!

  // swiftlint:disable:next force_unwrapping
  private static let appleDBURL = URL(string: "https://api.appledb.dev/ios/macOS/main.json")!

  // MARK: - Instance Properties

  private let deviceIdentifier = "VirtualMac2,1"

  // MARK: - Initializers

  public init() {}

  // MARK: - Private Type Methods

  /// Fetch the last commit date for macOS data from GitHub API
  private static func fetchGitHubLastCommitDate() async -> Date? {
    do {
      let (data, _) = try await URLSession.shared.data(from: githubCommitsURL)

      let commits = try JSONDecoder().decode([GitHubCommitsResponse].self, from: data)

      guard let firstCommit = commits.first else {
        Self.logger.warning(
          "No commits found in AppleDB GitHub repository"
        )
        return nil
      }

      // Parse ISO 8601 date
      let isoFormatter = ISO8601DateFormatter()
      guard let date = isoFormatter.date(from: firstCommit.commit.committer.date) else {
        Self.logger.warning(
          "Failed to parse commit date: \(firstCommit.commit.committer.date)"
        )
        return nil
      }

      Self.logger.debug(
        "AppleDB macOS data last updated: \(date) (commit: \(firstCommit.sha.prefix(7)))"
      )
      return date
    } catch {
      Self.logger.warning(
        "Failed to fetch GitHub commit date for AppleDB: \(error)"
      )
      // Fallback to HTTP Last-Modified header
      return await URLSession.shared.fetchLastModified(from: appleDBURL)
    }
  }

  /// Fetch macOS data from AppleDB API
  private static func fetchAppleDBData() async throws -> [AppleDBEntry] {
    Self.logger.debug("Fetching AppleDB data from \(appleDBURL)")

    let (data, _) = try await URLSession.shared.data(from: appleDBURL)

    let entries = try JSONDecoder().decode([AppleDBEntry].self, from: data)

    Self.logger.debug(
      "Fetched \(entries.count) total entries from AppleDB"
    )

    return entries
  }

  // MARK: - Public Methods

  /// Fetch all VirtualMac2,1 restore images from AppleDB
  public func fetch() async throws -> [RestoreImageRecord] {
    // Fetch when macOS data was last updated using GitHub API
    let sourceUpdatedAt = await Self.fetchGitHubLastCommitDate()

    // Fetch AppleDB data
    let entries = try await Self.fetchAppleDBData()

    // Filter for VirtualMac2,1 and map to RestoreImageRecord
    return
      entries
      .filter { $0.deviceMap.contains(deviceIdentifier) }
      .compactMap { entry in
        mapToRestoreImage(
          entry: entry,
          sourceUpdatedAt: sourceUpdatedAt,
          deviceIdentifier: deviceIdentifier
        )
      }
  }

  // MARK: - Private Instance Methods

  /// Map an AppleDB entry to RestoreImageRecord
  private func mapToRestoreImage(
    entry: AppleDBEntry,
    sourceUpdatedAt: Date?,
    deviceIdentifier: String
  ) -> RestoreImageRecord? {
    // Skip entries without a build number (required for unique identification)
    guard let build = entry.build else {
      Self.logger.debug(
        "Skipping AppleDB entry without build number: \(entry.version)"
      )
      return nil
    }

    // Determine if signed for VirtualMac2,1
    let isSigned = entry.signed.isSigned(for: deviceIdentifier)

    // Determine if prerelease
    let isPrerelease = entry.beta == true || entry.rc == true || entry.internal == true

    // Parse release date if available
    let releaseDate: Date?
    if !entry.released.isEmpty {
      let isoFormatter = ISO8601DateFormatter()
      releaseDate = isoFormatter.date(from: entry.released)
    } else {
      releaseDate = nil
    }

    // Find IPSW source
    guard let ipswSource = entry.sources?.first(where: { $0.type == "ipsw" }) else {
      Self.logger.debug(
        "No IPSW source found for build \(build)"
      )
      return nil
    }

    // Get preferred or first active link
    guard let link = ipswSource.links?.first(where: { $0.preferred == true || $0.active == true })
    else {
      Self.logger.debug(
        "No active download link found for build \(build)"
      )
      return nil
    }

    // Convert link.url String to URL
    guard let downloadURL = URL(string: link.url) else {
      Self.logger.debug(
        "Invalid download URL for build \(build): \(link.url)"
      )
      return nil
    }

    return RestoreImageRecord(
      version: entry.version,
      buildNumber: build,
      releaseDate: releaseDate ?? Date(),  // Fallback to current date
      downloadURL: downloadURL,
      fileSize: ipswSource.size ?? 0,
      sha256Hash: ipswSource.hashes?.sha2256 ?? "",
      sha1Hash: ipswSource.hashes?.sha1 ?? "",
      isSigned: isSigned,
      isPrerelease: isPrerelease,
      source: "appledb.dev",
      notes: "Device-specific signing status from AppleDB",
      sourceUpdatedAt: sourceUpdatedAt
    )
  }
}

// MARK: - Loggable Conformance
extension AppleDBFetcher: Loggable {
  public static let loggingCategory: BushelLogging.Category = .hub
}
