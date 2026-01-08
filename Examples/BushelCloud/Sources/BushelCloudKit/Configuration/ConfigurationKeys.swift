//
//  ConfigurationKeys.swift
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

import ConfigKeyKit
import Foundation

/// Configuration keys for reading from providers
internal enum ConfigurationKeys {
  // MARK: - CloudKit Configuration

  /// CloudKit configuration keys
  ///
  /// Auto-generates environment variable names from the key path.
  /// Example: "cloudkit.container_id" → ENV: CLOUDKIT_CONTAINER_ID
  internal enum CloudKit {
    internal static let containerID = ConfigKey<String>(
      "cloudkit.container_id",
      default: "iCloud.com.brightdigit.Bushel"
    )

    internal static let keyID = OptionalConfigKey<String>(
      "cloudkit.key_id"
    )

    internal static let privateKeyPath = OptionalConfigKey<String>(
      "cloudkit.private_key_path"
    )

    internal static let privateKey = OptionalConfigKey<String>(
      "cloudkit.private_key"
    )

    internal static let environment = OptionalConfigKey<String>(
      "cloudkit.environment"
    )
  }

  // MARK: - VirtualBuddy Configuration

  /// VirtualBuddy TSS API configuration keys
  ///
  /// Auto-generates ENV names (VIRTUALBUDDY_API_KEY).
  internal enum VirtualBuddy {
    internal static let apiKey = OptionalConfigKey<String>(
      "virtualbuddy.api_key"
    )
  }

  // MARK: - Fetch Configuration

  /// Fetch throttling configuration keys
  ///
  /// Uses `bushelPrefixed:` to add BUSHEL_ prefix to all environment variables.
  /// Example: "fetch.interval_global" → ENV: BUSHEL_FETCH_INTERVAL_GLOBAL
  internal enum Fetch {
    /// Generate per-source interval key dynamically
    /// - Parameter source: Data source identifier (e.g., "appledb.dev")
    /// - Returns: An OptionalConfigKey<Double> for the source-specific interval
    internal static func intervalKey(for source: String) -> OptionalConfigKey<Double> {
      let normalized = source.replacingOccurrences(of: ".", with: "_")
      return OptionalConfigKey<Double>(
        "fetch.interval.\(normalized)"
      )
    }
  }

  // MARK: - Sync Command Configuration

  /// Sync command configuration keys
  ///
  /// Uses `bushelPrefixed:` for BUSHEL_SYNC_* environment variables.
  internal enum Sync {
    internal static let dryRun = ConfigKey<Bool>(bushelPrefixed: "sync.dry_run")
    internal static let restoreImagesOnly = ConfigKey<Bool>(
      bushelPrefixed: "sync.restore_images_only"
    )
    internal static let xcodeOnly = ConfigKey<Bool>(bushelPrefixed: "sync.xcode_only")
    internal static let swiftOnly = ConfigKey<Bool>(bushelPrefixed: "sync.swift_only")
    internal static let noBetas = ConfigKey<Bool>(bushelPrefixed: "sync.no_betas")
    internal static let noAppleWiki = ConfigKey<Bool>(bushelPrefixed: "sync.no_apple_wiki")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "sync.verbose")
    internal static let force = ConfigKey<Bool>(bushelPrefixed: "sync.force")
    internal static let minInterval = OptionalConfigKey<Int>(bushelPrefixed: "sync.min_interval")
    internal static let source = OptionalConfigKey<String>(bushelPrefixed: "sync.source")
    internal static let jsonOutputFile = OptionalConfigKey<String>(bushelPrefixed: "sync.json_output_file")
  }

  // MARK: - Export Command Configuration

  /// Export command configuration keys
  ///
  /// Uses `bushelPrefixed:` for BUSHEL_EXPORT_* environment variables.
  internal enum Export {
    internal static let output = OptionalConfigKey<String>(bushelPrefixed: "export.output")
    internal static let pretty = ConfigKey<Bool>(bushelPrefixed: "export.pretty")
    internal static let signedOnly = ConfigKey<Bool>(bushelPrefixed: "export.signed_only")
    internal static let noBetas = ConfigKey<Bool>(bushelPrefixed: "export.no_betas")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "export.verbose")
  }

  // MARK: - Status Command Configuration

  /// Status command configuration keys
  ///
  /// Uses `bushelPrefixed:` for BUSHEL_STATUS_* environment variables.
  internal enum Status {
    internal static let errorsOnly = ConfigKey<Bool>(bushelPrefixed: "status.errors_only")
    internal static let detailed = ConfigKey<Bool>(bushelPrefixed: "status.detailed")
  }

  // MARK: - List Command Configuration

  /// List command configuration keys
  ///
  /// Uses `bushelPrefixed:` for BUSHEL_LIST_* environment variables.
  internal enum List {
    internal static let restoreImages = ConfigKey<Bool>(bushelPrefixed: "list.restore_images")
    internal static let xcodeVersions = ConfigKey<Bool>(bushelPrefixed: "list.xcode_versions")
    internal static let swiftVersions = ConfigKey<Bool>(bushelPrefixed: "list.swift_versions")
  }

  // MARK: - Clear Command Configuration

  /// Clear command configuration keys
  ///
  /// Uses `bushelPrefixed:` for BUSHEL_CLEAR_* environment variables.
  internal enum Clear {
    internal static let yes = ConfigKey<Bool>(bushelPrefixed: "clear.yes")
    internal static let verbose = ConfigKey<Bool>(bushelPrefixed: "clear.verbose")
  }
}
