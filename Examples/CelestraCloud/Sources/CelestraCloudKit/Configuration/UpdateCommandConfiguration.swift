//
//  UpdateCommandConfiguration.swift
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

public import Foundation

/// Configuration for the update command
public struct UpdateCommandConfiguration: Sendable {
  /// Delay between feed updates in seconds (default: 2.0)
  public var delay: Double

  /// Skip robots.txt validation (default: false)
  public var skipRobotsCheck: Bool

  /// Maximum failure count threshold for filtering feeds
  public var maxFailures: Int?

  /// Minimum subscriber count for filtering feeds
  public var minPopularity: Int?

  /// Only update feeds last attempted before this date
  public var lastAttemptedBefore: Date?

  /// Maximum number of feeds to query and update
  public var limit: Int?

  /// Path to write JSON output report (optional)
  public var jsonOutputPath: String?

  /// Initialize update command configuration
  /// - Parameters:
  ///   - delay: Delay between feed updates in seconds
  ///   - skipRobotsCheck: Skip robots.txt validation
  ///   - maxFailures: Maximum failure count threshold
  ///   - minPopularity: Minimum subscriber count
  ///   - lastAttemptedBefore: Only update feeds attempted before this date
  ///   - limit: Maximum number of feeds to query and update
  ///   - jsonOutputPath: Path to write JSON output report
  public init(
    delay: Double = 2.0,
    skipRobotsCheck: Bool = false,
    maxFailures: Int? = nil,
    minPopularity: Int? = nil,
    lastAttemptedBefore: Date? = nil,
    limit: Int? = nil,
    jsonOutputPath: String? = nil
  ) {
    self.delay = delay
    self.skipRobotsCheck = skipRobotsCheck
    self.maxFailures = maxFailures
    self.minPopularity = minPopularity
    self.lastAttemptedBefore = lastAttemptedBefore
    self.limit = limit
    self.jsonOutputPath = jsonOutputPath
  }
}
