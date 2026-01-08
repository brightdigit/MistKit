//
//  MrMacintoshFetcher.swift
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
public import BushelLogging
import Foundation
import Logging
import SwiftSoup

#if canImport(FelinePineSwift)
  import FelinePineSwift
#endif

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for macOS beta/RC restore images from Mr. Macintosh database
internal struct MrMacintoshFetcher: DataSourceFetcher, Sendable {
  internal typealias Record = [RestoreImageRecord]

  // MARK: - Error Types

  internal enum FetchError: Error {
    case invalidURL
    case invalidEncoding
  }

  // MARK: - Internal Methods

  /// Fetch beta and RC restore images from Mr. Macintosh
  internal func fetch() async throws -> [RestoreImageRecord] {
    let urlString =
      "https://mrmacintosh.com/apple-silicon-m1-full-macos-restore-ipsw-firmware-files-database/"
    guard let url = URL(string: urlString) else {
      throw FetchError.invalidURL
    }

    let (data, _) = try await URLSession.shared.data(from: url)
    guard let html = String(data: data, encoding: .utf8) else {
      throw FetchError.invalidEncoding
    }

    let doc = try SwiftSoup.parse(html)

    // Extract the page update date from <strong>UPDATED: MM/DD/YY</strong>
    var pageUpdatedAt: Date?
    if let strongElements = try? doc.select("strong"),
      let updateElement = strongElements.first(where: { element in
        (try? element.text().uppercased().starts(with: "UPDATED:")) == true
      }),
      let updateText = try? updateElement.text(),
      let dateString = updateText.split(separator: ":").last?.trimmingCharacters(in: .whitespaces)
    {
      pageUpdatedAt = parseDateMMDDYY(from: String(dateString))
      if let date = pageUpdatedAt {
        Self.logger.debug(
          "Mr. Macintosh page last updated: \(date)"
        )
      }
    }

    // Find all table rows
    let rows = try doc.select("table tr")

    let records = rows.compactMap { row in
      parseTableRow(row, pageUpdatedAt: pageUpdatedAt)
    }

    return records
  }

  // MARK: - Private Methods

  /// Parse a table row into a RestoreImageRecord
  private func parseTableRow(_ row: SwiftSoup.Element, pageUpdatedAt: Date?) -> RestoreImageRecord?
  {
    do {
      let cells = try row.select("td")
      guard cells.count >= 3 else {
        return nil
      }

      // Expected columns: Download Link | Version | Date | [Optional: Signed Status]
      // Extract filename and URL from first cell
      guard let linkElement = try cells[0].select("a").first(),
        let downloadURLString = try? linkElement.attr("href"),
        !downloadURLString.isEmpty,
        let downloadURL = URL(string: downloadURLString)
      else {
        return nil
      }

      let filename = try linkElement.text()

      // Parse filename like "UniversalMac_26.1_25B78_Restore.ipsw"
      // Extract version and build from filename
      guard filename.contains("UniversalMac") else {
        return nil
      }

      let components = filename.replacingOccurrences(of: ".ipsw", with: "")
        .components(separatedBy: "_")
      guard components.count >= 3 else {
        return nil
      }

      let version = components[1]
      let buildNumber = components[2]

      // Get version from second cell (more reliable)
      let versionFromCell = try cells[1].text()

      // Get date from third cell
      let dateStr = try cells[2].text()
      guard let releaseDate = parseDate(from: dateStr) else {
        Self.logger.warning(
          "Failed to parse date '\(dateStr)' for build \(buildNumber), skipping record"
        )
        return nil
      }

      // Check if signed (4th column if present)
      let isSigned: Bool? =
        cells.count >= 4 ? try cells[3].text().uppercased().contains("YES") : nil

      // Determine if it's a beta/RC release from filename or version
      let isPrerelease =
        filename.lowercased().contains("beta") || filename.lowercased().contains("rc")
        || versionFromCell.lowercased().contains("beta")
        || versionFromCell.lowercased().contains("rc")

      return RestoreImageRecord(
        version: version,
        buildNumber: buildNumber,
        releaseDate: releaseDate,
        downloadURL: downloadURL,
        fileSize: 0,  // Not provided
        sha256Hash: "",  // Not provided
        sha1Hash: "",  // Not provided
        isSigned: isSigned,
        isPrerelease: isPrerelease,
        source: "mrmacintosh.com",
        notes: nil,
        sourceUpdatedAt: pageUpdatedAt  // Date when Mr. Macintosh last updated the page
      )
    } catch {
      Self.logger.debug(
        "Failed to parse table row: \(error)"
      )
      return nil
    }
  }

  /// Parse date from Mr. Macintosh format (MM/DD/YY or M/D or M/DD)
  private func parseDate(from string: String) -> Date? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

    // Try formats with year first
    let formattersWithYear = [
      makeDateFormatter(format: "M/d/yy"),
      makeDateFormatter(format: "MM/dd/yy"),
      makeDateFormatter(format: "M/d/yyyy"),
      makeDateFormatter(format: "MM/dd/yyyy"),
    ]

    for formatter in formattersWithYear {
      if let date = formatter.date(from: trimmed) {
        return date
      }
    }

    // If no year, assume current or previous year
    let formattersNoYear = [
      makeDateFormatter(format: "M/d"),
      makeDateFormatter(format: "MM/dd"),
    ]

    for formatter in formattersNoYear {
      if let date = formatter.date(from: trimmed) {
        // Add current year
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var components = calendar.dateComponents([.month, .day], from: date)
        components.year = currentYear

        // If date is in the future, use previous year
        if let dateWithYear = calendar.date(from: components), dateWithYear > Date() {
          components.year = currentYear - 1
        }

        return calendar.date(from: components)
      }
    }

    return nil
  }

  /// Parse date from page update format (MM/DD/YY)
  private func parseDateMMDDYY(from string: String) -> Date? {
    let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
    let formatter = makeDateFormatter(format: "MM/dd/yy")
    return formatter.date(from: trimmed)
  }

  private func makeDateFormatter(format: String) -> DateFormatter {
    let formatter = DateFormatter()
    formatter.dateFormat = format
    formatter.locale = Locale(identifier: "en_US_POSIX")
    return formatter
  }
}

// MARK: - Loggable Conformance
extension MrMacintoshFetcher: Loggable {
  internal static let loggingCategory: BushelLogging.Category = .hub
}
