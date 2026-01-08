//
//  ConfigurationLoader+Loading.swift
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

// MARK: - Configuration Loading

extension ConfigurationLoader {
  /// Load the complete configuration from all providers
  public func loadConfiguration() async throws -> BushelConfiguration {
    // CloudKit configuration (automatic CLI → ENV → default fallback)
    let cloudKit = CloudKitConfiguration(
      containerID: read(ConfigurationKeys.CloudKit.containerID),
      keyID: read(ConfigurationKeys.CloudKit.keyID),
      privateKeyPath: read(ConfigurationKeys.CloudKit.privateKeyPath),
      privateKey: read(ConfigurationKeys.CloudKit.privateKey),
      // Default to development
      environment: read(ConfigurationKeys.CloudKit.environment) ?? "development"
    )

    // VirtualBuddy configuration
    let virtualBuddy = VirtualBuddyConfiguration(
      apiKey: read(ConfigurationKeys.VirtualBuddy.apiKey)
    )

    // Fetch configuration: Start with BushelKit's environment loading, then override with CLI
    var fetch = FetchConfiguration.loadFromEnvironment()

    // Override global interval if --min-interval provided
    if let minInterval = read(ConfigurationKeys.Sync.minInterval) {
      fetch = FetchConfiguration(
        globalMinimumFetchInterval: TimeInterval(minInterval),
        perSourceIntervals: fetch.perSourceIntervals,
        useDefaults: true
      )
    }

    // Override per-source intervals from CLI or ENV
    var perSourceIntervals = fetch.perSourceIntervals

    for source in DataSource.allCases {
      // Try CLI arg first (e.g., "fetch.interval.appledb_dev")
      // Then try ENV var (e.g., "BUSHEL_FETCH_INTERVAL_APPLEDB_DEV")
      let intervalKey = ConfigurationKeys.Fetch.intervalKey(for: source.rawValue)
      if let interval = read(intervalKey) {
        perSourceIntervals[source.rawValue] = interval
      }
    }

    // Rebuild fetch configuration with updated intervals if any were found
    if !perSourceIntervals.isEmpty {
      fetch = FetchConfiguration(
        globalMinimumFetchInterval: fetch.globalMinimumFetchInterval,
        perSourceIntervals: perSourceIntervals,
        useDefaults: fetch.useDefaults
      )
    }

    // Sync command configuration
    let sync = SyncConfiguration(
      dryRun: read(ConfigurationKeys.Sync.dryRun),
      restoreImagesOnly: read(ConfigurationKeys.Sync.restoreImagesOnly),
      xcodeOnly: read(ConfigurationKeys.Sync.xcodeOnly),
      swiftOnly: read(ConfigurationKeys.Sync.swiftOnly),
      noBetas: read(ConfigurationKeys.Sync.noBetas),
      noAppleWiki: read(ConfigurationKeys.Sync.noAppleWiki),
      verbose: read(ConfigurationKeys.Sync.verbose),
      force: read(ConfigurationKeys.Sync.force),
      minInterval: read(ConfigurationKeys.Sync.minInterval),
      source: read(ConfigurationKeys.Sync.source),
      jsonOutputFile: read(ConfigurationKeys.Sync.jsonOutputFile)
    )

    // Export command configuration
    let export = ExportConfiguration(
      output: read(ConfigurationKeys.Export.output),
      pretty: read(ConfigurationKeys.Export.pretty),
      signedOnly: read(ConfigurationKeys.Export.signedOnly),
      noBetas: read(ConfigurationKeys.Export.noBetas),
      verbose: read(ConfigurationKeys.Export.verbose)
    )

    // Status command configuration
    let status = StatusConfiguration(
      errorsOnly: read(ConfigurationKeys.Status.errorsOnly),
      detailed: read(ConfigurationKeys.Status.detailed)
    )

    // List command configuration
    let list = ListConfiguration(
      restoreImages: read(ConfigurationKeys.List.restoreImages),
      xcodeVersions: read(ConfigurationKeys.List.xcodeVersions),
      swiftVersions: read(ConfigurationKeys.List.swiftVersions)
    )

    // Clear command configuration
    let clear = ClearConfiguration(
      yes: read(ConfigurationKeys.Clear.yes),
      verbose: read(ConfigurationKeys.Clear.verbose)
    )

    return BushelConfiguration(
      cloudKit: cloudKit,
      virtualBuddy: virtualBuddy,
      fetch: fetch,
      sync: sync,
      export: export,
      status: status,
      list: list,
      clear: clear
    )
  }
}
