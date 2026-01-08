//
//  SwiftVersionFetcher.swift
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
import SwiftSoup

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for Swift compiler versions from swiftversion.net
internal struct SwiftVersionFetcher: DataSourceFetcher, Sendable {
  internal typealias Record = [SwiftVersionRecord]

  // MARK: - Internal Models

  private struct SwiftVersionEntry {
    let date: Date
    let swiftVersion: String
    let xcodeVersion: String
  }

  internal enum FetchError: Error {
    case invalidEncoding
  }

  // MARK: - Type Properties

  // swiftlint:disable:next force_unwrapping
  private static let swiftVersionURL = URL(string: "https://swiftversion.net")!

  // MARK: - Internal Methods

  /// Fetch all Swift versions from swiftversion.net
  internal func fetch() async throws -> [SwiftVersionRecord] {
    let (data, _) = try await URLSession.shared.data(from: Self.swiftVersionURL)
    guard let html = String(data: data, encoding: .utf8) else {
      throw FetchError.invalidEncoding
    }

    let doc = try SwiftSoup.parse(html)
    let rows = try doc.select("tbody tr.table-entry")

    var entries: [SwiftVersionEntry] = []
    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "dd MMM yy"

    for row in rows {
      let cells = try row.select("td")
      guard cells.count == 3 else { continue }

      let dateStr = try cells[0].text()
      let swiftVer = try cells[1].text()
      let xcodeVer = try cells[2].text()

      guard let date = dateFormatter.date(from: dateStr) else {
        print("Warning: Could not parse date: \(dateStr)")
        continue
      }

      entries.append(
        SwiftVersionEntry(
          date: date,
          swiftVersion: swiftVer,
          xcodeVersion: xcodeVer
        )
      )
    }

    return entries.map { entry in
      SwiftVersionRecord(
        version: entry.swiftVersion,
        releaseDate: entry.date,
        downloadURL: URL(string: "https://swift.org/download/"),  // Generic download page
        isPrerelease: entry.swiftVersion.contains("beta")
          || entry.swiftVersion.contains("snapshot"),
        notes: "Bundled with Xcode \(entry.xcodeVersion)"
      )
    }
  }
}
