//  StatusCommand.swift
//  Created by Claude Code

import ArgumentParser
import Foundation
internal import MistKit

struct StatusCommand: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "status",
    abstract: "Show data source fetch status and metadata",
    discussion: """
      Displays information about when each data source was last fetched,
      when the source was last updated, record counts, and next eligible fetch time.

      This command queries CloudKit for DataSourceMetadata records to show
      the current state of all data sources.
      """
  )

  // MARK: - Required Options

  @Option(name: .shortAndLong, help: "CloudKit container identifier")
  var containerIdentifier: String = "iCloud.com.brightdigit.Bushel"

  @Option(name: .long, help: "Server-to-Server Key ID (or set CLOUDKIT_KEY_ID)")
  var keyID: String = ""

  @Option(name: .long, help: "Path to private key .pem file (or set CLOUDKIT_PRIVATE_KEY_PATH)")
  var keyFile: String = ""

  // MARK: - Display Options

  @Flag(name: .long, help: "Show only sources with errors")
  var errorsOnly: Bool = false

  @Flag(name: .long, help: "Show detailed timing information")
  var detailed: Bool = false

  @Flag(name: .long, help: "Disable log redaction for debugging (shows actual CloudKit field names in errors)")
  var noRedaction: Bool = false

  // MARK: - Execution

  mutating func run() async throws {
    // Disable log redaction for debugging if requested
    if noRedaction {
      setenv("MISTKIT_DISABLE_LOG_REDACTION", "1", 1)
    }

    // Get Server-to-Server credentials from environment if not provided
    let resolvedKeyID = keyID.isEmpty ?
      ProcessInfo.processInfo.environment["CLOUDKIT_KEY_ID"] ?? "" :
      keyID

    let resolvedKeyFile = keyFile.isEmpty ?
      ProcessInfo.processInfo.environment["CLOUDKIT_PRIVATE_KEY_PATH"] ?? "" :
      keyFile

    guard !resolvedKeyID.isEmpty, !resolvedKeyFile.isEmpty else {
      print("❌ Error: CloudKit Server-to-Server Key credentials are required")
      print("")
      print("   Provide via command-line flags:")
      print("     --key-id YOUR_KEY_ID --key-file ./private-key.pem")
      print("")
      print("   Or set environment variables:")
      print("     export CLOUDKIT_KEY_ID=\"YOUR_KEY_ID\"")
      print("     export CLOUDKIT_PRIVATE_KEY_PATH=\"./private-key.pem\"")
      print("")
      throw ExitCode.failure
    }

    // Create CloudKit service
    let cloudKitService = try BushelCloudKitService(
      containerIdentifier: containerIdentifier,
      keyID: resolvedKeyID,
      privateKeyPath: resolvedKeyFile
    )

    // Load configuration to show intervals
    let configuration = FetchConfiguration.loadFromEnvironment()

    // Fetch all metadata records
    print("\n📊 Data Source Status")
    print(String(repeating: "=", count: 80))

    let allMetadata = try await fetchAllMetadata(cloudKitService: cloudKitService)

    if allMetadata.isEmpty {
      print("\n   No metadata records found. Run 'bushel-images sync' to populate metadata.")
      return
    }

    // Filter if needed
    let metadata = errorsOnly ? allMetadata.filter { $0.lastError != nil } : allMetadata

    if metadata.isEmpty, errorsOnly {
      print("\n   ✅ No sources with errors!")
      return
    }

    // Display metadata
    for meta in metadata.sorted(by: { $0.recordTypeName < $1.recordTypeName || ($0.recordTypeName == $1.recordTypeName && $0.sourceName < $1.sourceName) }) {
      printMetadata(meta, configuration: configuration, detailed: detailed)
    }

    print(String(repeating: "=", count: 80))
  }

  // MARK: - Private Helpers

  private func fetchAllMetadata(cloudKitService: BushelCloudKitService) async throws -> [DataSourceMetadata] {
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

  private func printMetadata(
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
        print("  Next Fetch:      \(formatDate(nextFetchTime)) (in \(formatTimeInterval(timeUntilNext)))")
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

  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  private func formatTimeInterval(_ interval: TimeInterval) -> String {
    let absInterval = abs(interval)

    if absInterval < 60 {
      return "\(Int(absInterval))s"
    } else if absInterval < 3600 {
      let minutes = Int(absInterval / 60)
      return "\(minutes)m"
    } else if absInterval < 86400 {
      let hours = Int(absInterval / 3600)
      let minutes = Int((absInterval.truncatingRemainder(dividingBy: 3600)) / 60)
      return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
    } else {
      let days = Int(absInterval / 86400)
      let hours = Int((absInterval.truncatingRemainder(dividingBy: 86400)) / 3600)
      return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
    }
  }
}
