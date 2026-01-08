//
//  DataSourcePipeline.swift
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
import BushelLogging
import Foundation

/// Orchestrates fetching data from all sources with deduplication and relationship resolution
public struct DataSourcePipeline: Sendable {
  // MARK: - Configuration

  public struct Options: Sendable {
    public var includeRestoreImages: Bool = true
    public var includeXcodeVersions: Bool = true
    public var includeSwiftVersions: Bool = true
    public var includeBetaReleases: Bool = true
    public var includeAppleDB: Bool = true
    public var includeTheAppleWiki: Bool = true
    public var includeVirtualBuddy: Bool = true
    public var force: Bool = false
    public var specificSource: String?

    public init(
      includeRestoreImages: Bool = true,
      includeXcodeVersions: Bool = true,
      includeSwiftVersions: Bool = true,
      includeBetaReleases: Bool = true,
      includeAppleDB: Bool = true,
      includeTheAppleWiki: Bool = true,
      includeVirtualBuddy: Bool = true,
      force: Bool = false,
      specificSource: String? = nil
    ) {
      self.includeRestoreImages = includeRestoreImages
      self.includeXcodeVersions = includeXcodeVersions
      self.includeSwiftVersions = includeSwiftVersions
      self.includeBetaReleases = includeBetaReleases
      self.includeAppleDB = includeAppleDB
      self.includeTheAppleWiki = includeTheAppleWiki
      self.includeVirtualBuddy = includeVirtualBuddy
      self.force = force
      self.specificSource = specificSource
    }
  }

  // MARK: - Results

  public struct FetchResult: Sendable {
    public var restoreImages: [RestoreImageRecord]
    public var xcodeVersions: [XcodeVersionRecord]
    public var swiftVersions: [SwiftVersionRecord]

    public init(
      restoreImages: [RestoreImageRecord],
      xcodeVersions: [XcodeVersionRecord],
      swiftVersions: [SwiftVersionRecord]
    ) {
      self.restoreImages = restoreImages
      self.xcodeVersions = xcodeVersions
      self.swiftVersions = swiftVersions
    }
  }

  // MARK: - Dependencies

  internal let configuration: FetchConfiguration

  // MARK: - Initialization

  public init(
    configuration: FetchConfiguration = FetchConfiguration.loadFromEnvironment()
  ) {
    self.configuration = configuration
  }

  // MARK: - Public API

  /// Fetch all data from configured sources
  public func fetch(options: Options = Options()) async throws -> FetchResult {
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
      // Resolve XcodeVersion → RestoreImage references now that we have both datasets
      xcodeVersions = resolveXcodeVersionReferences(xcodeVersions, restoreImages: restoreImages)
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

  // MARK: - Metadata Tracking

  /// Check if a source should be fetched based on throttling rules
  private func shouldFetch(
    source _: String,
    recordType _: String,
    force: Bool
  ) async -> (shouldFetch: Bool, metadata: DataSourceMetadata?) {
    // If force flag is set, always fetch
    guard !force else {
      return (true, nil)
    }

    // No CloudKit service in BushelCloudData - always fetch
    // CloudKit metadata checking will be re-added in Phase 4
    return (true, nil)
  }

  /// Wrap a fetch operation with metadata tracking
  internal func fetchWithMetadata<T>(
    source: String,
    recordType: String,
    options: Options,
    fetcher: () async throws -> [T]
  ) async throws -> [T] {
    // Check if we should skip this source based on --source flag
    if let specificSource = options.specificSource, specificSource != source {
      print("   ⏭️  Skipping \(source) (--source=\(specificSource))")
      return []
    }

    // Check throttling
    let (shouldFetch, existingMetadata) = await shouldFetch(
      source: source,
      recordType: recordType,
      force: options.force
    )

    if !shouldFetch {
      if let metadata = existingMetadata {
        let timeSinceLastFetch = Date().timeIntervalSince(metadata.lastFetchedAt)
        let minInterval = configuration.minimumInterval(for: source) ?? 0
        let timeRemaining = minInterval - timeSinceLastFetch
        let message =
          "⏰ Skipping \(source) " + "(last fetched \(Int(timeSinceLastFetch / 60))m ago, "
          + "wait \(Int(timeRemaining / 60))m)"
        print("   \(message)")
      }
      return []
    }

    do {
      let results = try await fetcher()

      // Metadata sync disabled in BushelCloudData (no CloudKit dependency)
      // Will be re-enabled in Phase 4 when using BushelKit

      return results
    } catch {
      // Metadata sync disabled in BushelCloudData (no CloudKit dependency)
      // Will be re-enabled in Phase 4 when using BushelKit

      throw error
    }
  }
}
