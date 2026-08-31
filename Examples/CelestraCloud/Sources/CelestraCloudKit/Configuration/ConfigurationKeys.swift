//
//  ConfigurationKeys.swift
//  CelestraCloud
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
internal import Foundation
internal import MistKitConfiguration

/// Configuration keys for reading from providers.
///
/// CloudKit credentials come from ``CloudKitConfigurationKeys``; Celestra-only update
/// options stay here as typed `ConfigKey`/`OptionalConfigKey` values.
internal enum ConfigurationKeys {
  /// Default CloudKit container for Celestra.
  internal static let defaultContainerID = "iCloud.com.brightdigit.Celestra"

  /// CloudKit credential keys with Celestra's container default.
  internal static let cloudKit = CloudKitConfigurationKeys(
    defaultContainerID: defaultContainerID
  )

  internal enum Update {
    internal static let delay = ConfigKey<Double>("update.delay", default: 2.0)
    internal static let skipRobotsCheck = ConfigKey<Bool>(
      "update.skip-robots-check",
      default: false
    )
    internal static let maxFailures = OptionalConfigKey<Int>("update.max-failures")
    internal static let minPopularity = OptionalConfigKey<Int>("update.min-popularity")
    internal static let lastAttemptedBefore = OptionalConfigKey<Date>(
      "update.last-attempted-before"
    )
    internal static let limit = OptionalConfigKey<Int>("update.limit")
    internal static let jsonOutputPath = OptionalConfigKey<String>("update.json-output-path")
  }
}
