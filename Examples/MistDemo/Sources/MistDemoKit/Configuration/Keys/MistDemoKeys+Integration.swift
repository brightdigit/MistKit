//
//  MistDemoKeys+Integration.swift
//  MistDemo
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

internal import ConfigKeyKit

extension MistDemoKeys {
  /// Keys for the `test-public` / `test-private` integration runners and the
  /// error/validation demos.
  internal enum Integration {
    /// `--record-count` / `CLOUDKIT_RECORD_COUNT`.
    internal static let recordCount = ConfigKey<Int>(
      "record.count", envPrefix: MistDemoKeys.envPrefix, default: 10
    )

    /// `--asset-size` / `CLOUDKIT_ASSET_SIZE`, in bytes.
    internal static let assetSize = ConfigKey<Int>(
      "asset.size", envPrefix: MistDemoKeys.envPrefix, default: 100
    )

    /// `--skip-cleanup` / `CLOUDKIT_SKIP_CLEANUP`.
    internal static let skipCleanup = ConfigKey<Bool>(
      "skip.cleanup", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--lookup-email` / `CLOUDKIT_LOOKUP_EMAIL`.
    internal static let lookupEmail = OptionalConfigKey<String>(
      "lookup.email", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--share-short-guid` / `CLOUDKIT_SHARE_SHORT_GUID`.
    internal static let shareShortGUID = OptionalConfigKey<String>(
      "share.short.guid", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--discover-emails` / `CLOUDKIT_DISCOVER_EMAILS`, comma separated.
    internal static let discoverEmails = OptionalConfigKey<String>(
      "discover.emails", envPrefix: MistDemoKeys.envPrefix
    )

    /// `--scenario` / `CLOUDKIT_SCENARIO`.
    internal static let scenario = ConfigKey<String>(
      "scenario", envPrefix: MistDemoKeys.envPrefix, default: "all"
    )

    /// `--validate-skip-network` / `CLOUDKIT_VALIDATE_SKIP_NETWORK`.
    internal static let validateSkipNetwork = ConfigKey<Bool>(
      "validate.skip-network", envPrefix: MistDemoKeys.envPrefix, default: false
    )

    /// `--validate-test-query` / `CLOUDKIT_VALIDATE_TEST_QUERY`.
    internal static let validateTestQuery = ConfigKey<Bool>(
      "validate.test-query", envPrefix: MistDemoKeys.envPrefix, default: false
    )
  }
}
