//
//  IPSWVersion.swift
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

import Foundation

/// IPSW metadata from TheAppleWiki
internal struct IPSWVersion: Codable, Sendable {
  internal let version: String
  internal let buildNumber: String
  internal let deviceModel: String
  internal let fileName: String
  internal let fileSize: String
  internal let sha1: String
  internal let releaseDate: Date?
  internal let url: URL?

  // MARK: - Computed Properties

  /// Parse file size string to Int for CloudKit
  /// Examples: "10.2 GB" -> bytes, "1.5 MB" -> bytes
  internal var fileSizeInBytes: Int? {
    let components = fileSize.components(separatedBy: " ")
    guard components.count == 2,
      let size = Double(components[0])
    else {
      return nil
    }

    let unit = components[1].uppercased()
    let multiplier: Double =
      switch unit {
      case "GB": 1_000_000_000
      case "MB": 1_000_000
      case "KB": 1_000
      case "BYTES", "B": 1
      default: 0
      }

    guard multiplier > 0 else {
      return nil
    }
    return Int(size * multiplier)
  }

  /// Detect if this is a prerelease version (beta, RC, etc.)
  internal var isPrerelease: Bool {
    let lowercased = version.lowercased()
    return lowercased.contains("beta")
      || lowercased.contains("rc")
      || lowercased.contains("gm seed")
      || lowercased.contains("developer preview")
  }

  /// Validate that all required fields are present
  internal var isValid: Bool {
    !version.isEmpty
      && !buildNumber.isEmpty
      && !deviceModel.isEmpty
      && !fileName.isEmpty
      && !sha1.isEmpty
      && url != nil
  }
}
