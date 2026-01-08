//
//  StatusCommand.swift
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

import BushelCloudKit
import BushelFoundation
import Foundation
internal import MistKit

internal enum StatusCommand {
  internal static func run(_ args: [String]) async throws {
    // Load configuration using Swift Configuration
    let loader = ConfigurationLoader()
    let rawConfig = try await loader.loadConfiguration()
    let config = try rawConfig.validated()

    // Create CloudKit service
    let cloudKitService: BushelCloudKitService
    if let pemString = config.cloudKit.privateKey {
      cloudKitService = try BushelCloudKitService(
        containerIdentifier: config.cloudKit.containerID,
        keyID: config.cloudKit.keyID,
        pemString: pemString,
        environment: config.cloudKit.environment
      )
    } else {
      cloudKitService = try BushelCloudKitService(
        containerIdentifier: config.cloudKit.containerID,
        keyID: config.cloudKit.keyID,
        privateKeyPath: config.cloudKit.privateKeyPath,
        environment: config.cloudKit.environment
      )
    }

    // Load configuration to show intervals
    let configuration = config.fetch ?? FetchConfiguration.loadFromEnvironment()

    // Fetch all metadata records
    print("\n📊 Data Source Status")
    print(String(repeating: "=", count: 80))

    let allMetadata = try await fetchAllMetadata(cloudKitService: cloudKitService)

    if allMetadata.isEmpty {
      print("\n   No metadata records found. Run 'bushel-cloud sync' to populate metadata.")
      return
    }

    // Filter if needed
    let errorsOnly = config.status?.errorsOnly ?? false
    let metadata = errorsOnly ? allMetadata.filter { $0.lastError != nil } : allMetadata

    if metadata.isEmpty, errorsOnly {
      print("\n   ✅ No sources with errors!")
      return
    }

    // Display metadata
    let detailed = config.status?.detailed ?? false
    for meta in metadata.sorted(by: {
      $0.recordTypeName < $1.recordTypeName
        || ($0.recordTypeName == $1.recordTypeName && $0.sourceName < $1.sourceName)
    }) {
      printMetadata(meta, configuration: configuration, detailed: detailed)
    }

    print(String(repeating: "=", count: 80))
  }

  // MARK: - Private Helpers

  private static func fetchAllMetadata(cloudKitService: BushelCloudKitService) async throws
    -> [DataSourceMetadata]
  {
    let records = try await cloudKitService.queryRecords(recordType: "DataSourceMetadata")

    var metadataList: [DataSourceMetadata] = []

    for record in records {
      guard let sourceName = record.fields["sourceName"]?.stringValue,
        let recordTypeName = record.fields["recordTypeName"]?.stringValue,
        let lastFetchedAt = record.fields["lastFetchedAt"]?.dateValue
      else {
        continue
      }

      let sourceUpdatedAt = record.fields["sourceUpdatedAt"]?.dateValue
      let recordCount = record.fields["recordCount"]?.intValue ?? 0
      let fetchDurationSeconds = record.fields["fetchDurationSeconds"]?.doubleValue ?? 0
      let lastError = record.fields["lastError"]?.stringValue

      metadataList.append(
        DataSourceMetadata(
          sourceName: sourceName,
          recordTypeName: recordTypeName,
          lastFetchedAt: lastFetchedAt,
          sourceUpdatedAt: sourceUpdatedAt,
          recordCount: recordCount,
          fetchDurationSeconds: fetchDurationSeconds,
          lastError: lastError
        )
      )
    }

    return metadataList
  }

  private static func printMetadata(
    _ metadata: DataSourceMetadata,
    configuration: FetchConfiguration,
    detailed: Bool
  ) {
    let now = Date()
    let timeSinceLastFetch = now.timeIntervalSince(metadata.lastFetchedAt)

    // Header
    print("\n\(metadata.sourceName) (\(metadata.recordTypeName))")
    print(String(repeating: "-", count: 80))

    // Last fetched
    let lastFetchedStr = formatDate(metadata.lastFetchedAt)
    let timeAgoStr = formatTimeInterval(timeSinceLastFetch)
    print("  Last Fetched:    \(lastFetchedStr) (\(timeAgoStr) ago)")

    // Source last updated
    if let sourceUpdated = metadata.sourceUpdatedAt {
      let sourceUpdatedStr = formatDate(sourceUpdated)
      let sourceTimeAgo = formatTimeInterval(now.timeIntervalSince(sourceUpdated))
      print("  Source Updated:  \(sourceUpdatedStr) (\(sourceTimeAgo) ago)")
    }

    // Record count
    print("  Record Count:    \(metadata.recordCount)")

    // Fetch duration (if detailed)
    if detailed {
      print("  Fetch Duration:  \(String(format: "%.2f", metadata.fetchDurationSeconds))s")
    }

    // Next eligible fetch
    if let minInterval = configuration.minimumInterval(for: metadata.sourceName) {
      let nextFetchTime = metadata.lastFetchedAt.addingTimeInterval(minInterval)
      let timeUntilNext = nextFetchTime.timeIntervalSince(now)

      if timeUntilNext > 0 {
        print(
          "  Next Fetch:      \(formatDate(nextFetchTime)) (in \(formatTimeInterval(timeUntilNext)))"
        )
      } else {
        print("  Next Fetch:      ✅ Ready now")
      }

      if detailed {
        print("  Min Interval:    \(formatTimeInterval(minInterval))")
      }
    } else {
      print("  Next Fetch:      ✅ No throttling")
    }

    // Error status
    if let error = metadata.lastError {
      print("  ⚠️  Last Error:    \(error)")
    }
  }

  private static func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private static func formatTimeInterval(_ interval: TimeInterval) -> String {
    let absInterval = abs(interval)

    if absInterval < 60 {
      return "\(Int(absInterval))s"
    } else if absInterval < 3_600 {
      let minutes = Int(absInterval / 60)
      return "\(minutes)m"
    } else if absInterval < 86_400 {
      let hours = Int(absInterval / 3_600)
      let minutes = Int((absInterval.truncatingRemainder(dividingBy: 3_600)) / 60)
      return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    } else {
      let days = Int(absInterval / 86_400)
      let hours = Int((absInterval.truncatingRemainder(dividingBy: 86_400)) / 3_600)
      return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
    }
  }
}
