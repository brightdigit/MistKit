//
//  ConfigurationKeys.swift
//  CelestraCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

/// Configuration keys for reading from providers
internal enum ConfigurationKeys {
  internal enum CloudKit {
    internal static let containerID = "cloudkit.container_id"
    internal static let containerIDEnv = "CLOUDKIT_CONTAINER_ID"
    internal static let keyID = "cloudkit.key_id"
    internal static let keyIDEnv = "CLOUDKIT_KEY_ID"
    internal static let privateKeyPath = "cloudkit.private_key_path"
    internal static let privateKeyPathEnv = "CLOUDKIT_PRIVATE_KEY_PATH"
    internal static let environment = "cloudkit.environment"
    internal static let environmentEnv = "CLOUDKIT_ENVIRONMENT"
  }

  internal enum Update {
    internal static let delay = "update.delay"
    internal static let delayEnv = "UPDATE_DELAY"
    internal static let skipRobotsCheck = "update.skip_robots_check"
    internal static let skipRobotsCheckEnv = "UPDATE_SKIP_ROBOTS_CHECK"
    internal static let maxFailures = "update.max_failures"
    internal static let maxFailuresEnv = "UPDATE_MAX_FAILURES"
    internal static let minPopularity = "update.min_popularity"
    internal static let minPopularityEnv = "UPDATE_MIN_POPULARITY"
    internal static let lastAttemptedBefore = "update.last_attempted_before"
    internal static let lastAttemptedBeforeEnv = "UPDATE_LAST_ATTEMPTED_BEFORE"
    internal static let limit = "update.limit"
    internal static let limitEnv = "UPDATE_LIMIT"
    internal static let jsonOutputPath = "update.json-output-path"
    internal static let jsonOutputPathEnv = "UPDATE_JSON_OUTPUT_PATH"
  }
}
