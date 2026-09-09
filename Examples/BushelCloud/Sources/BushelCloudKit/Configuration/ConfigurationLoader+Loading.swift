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

internal import BushelFoundation
internal import ConfigKeyKit
internal import Foundation
internal import MistKitConfiguration

// MARK: - Configuration Loading

extension ConfigurationLoader {
  /// Load the complete configuration from all providers
  public func loadConfiguration() async throws -> BushelConfiguration {
    let cloudKit = configReader.readCloudKitConfiguration(keys: ConfigurationKeys.cloudKit)

    // VirtualBuddy configuration
    let virtualBuddy = VirtualBuddyConfiguration(
      apiKey: configReader.read(ConfigurationKeys.VirtualBuddy.apiKey)
    )

    // Fetch configuration: Start with BushelKit's environment loading, then override with CLI
    var fetch = FetchConfiguration.loadFromEnvironment()

    // Override global interval if --min-interval provided
    if let minInterval = configReader.read(ConfigurationKeys.Sync.minInterval) {
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
      if let interval = configReader.read(intervalKey) {
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
      dryRun: configReader.read(ConfigurationKeys.Sync.dryRun),
      restoreImagesOnly: configReader.read(ConfigurationKeys.Sync.restoreImagesOnly),
      xcodeOnly: configReader.read(ConfigurationKeys.Sync.xcodeOnly),
      swiftOnly: configReader.read(ConfigurationKeys.Sync.swiftOnly),
      noBetas: configReader.read(ConfigurationKeys.Sync.noBetas),
      noAppleWiki: configReader.read(ConfigurationKeys.Sync.noAppleWiki),
      verbose: configReader.read(ConfigurationKeys.Sync.verbose),
      force: configReader.read(ConfigurationKeys.Sync.force),
      minInterval: configReader.read(ConfigurationKeys.Sync.minInterval),
      source: configReader.read(ConfigurationKeys.Sync.source),
      jsonOutputFile: configReader.read(ConfigurationKeys.Sync.jsonOutputFile)
    )

    // Export command configuration
    let export = ExportConfiguration(
      output: configReader.read(ConfigurationKeys.Export.output),
      pretty: configReader.read(ConfigurationKeys.Export.pretty),
      signedOnly: configReader.read(ConfigurationKeys.Export.signedOnly),
      noBetas: configReader.read(ConfigurationKeys.Export.noBetas),
      verbose: configReader.read(ConfigurationKeys.Export.verbose)
    )

    // Status command configuration
    let status = StatusConfiguration(
      errorsOnly: configReader.read(ConfigurationKeys.Status.errorsOnly),
      detailed: configReader.read(ConfigurationKeys.Status.detailed)
    )

    // List command configuration
    let list = ListConfiguration(
      restoreImages: configReader.read(ConfigurationKeys.List.restoreImages),
      xcodeVersions: configReader.read(ConfigurationKeys.List.xcodeVersions),
      swiftVersions: configReader.read(ConfigurationKeys.List.swiftVersions)
    )

    // Clear command configuration
    let clear = ClearConfiguration(
      yes: configReader.read(ConfigurationKeys.Clear.yes),
      verbose: configReader.read(ConfigurationKeys.Clear.verbose)
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
