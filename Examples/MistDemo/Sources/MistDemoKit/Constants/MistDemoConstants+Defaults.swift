//
//  MistDemoConstants+Defaults.swift
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

import Foundation

extension MistDemoConstants {
  /// Default values for configuration parameters.
  public enum Defaults {
    /// Default zone name.
    public static let zone = "_defaultZone"
    /// Default record type.
    public static let recordType = "Note"
    /// Default host address.
    public static let host = "127.0.0.1"
    /// Default port number.
    public static let port = 8_080
    /// Default output format.
    public static let outputFormat = "json"
    /// Default query result limit.
    public static let queryLimit = 20
    /// Default CloudKit environment.
    public static let environment = "development"
    /// Default CloudKit database.
    public static let database = "private"
    /// Default container identifier.
    public static let containerIdentifier =
      "iCloud.com.brightdigit.MistDemo"
  }

  /// Numeric limits and ranges.
  public enum Limits {
    /// Minimum query limit.
    public static let minQueryLimit = 1
    /// Maximum query limit.
    public static let maxQueryLimit = 200
    /// Minimum random suffix value.
    public static let randomSuffixMin = 1_000
    /// Maximum random suffix value.
    public static let randomSuffixMax = 9_999
  }

  /// Timeout values in milliseconds.
  public enum Timeouts {
    /// Auth server timeout (5 minutes).
    public static let authServer = 300_000
    /// Auth completion delay (1 second).
    public static let authCompletionDelay = 1_000
  }
}
