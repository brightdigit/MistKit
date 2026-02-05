//
//  IPSWParser.swift
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

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

// MARK: - Errors

internal enum TheAppleWikiError: LocalizedError {
  case invalidURL(String)
  case networkError(underlying: any Error)
  case parsingError(String)
  case noDataFound

  internal var errorDescription: String? {
    switch self {
    case .invalidURL(let url):
      return "Invalid URL: \(url)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .parsingError(let details):
      return "Parsing error: \(details)"
    case .noDataFound:
      return "No IPSW data found"
    }
  }
}

// MARK: - Parser

/// Fetches macOS IPSW metadata from TheAppleWiki.com
@available(macOS 12.0, *)
internal struct IPSWParser: Sendable {
  private let baseURL = "https://theapplewiki.com"
  private let apiEndpoint = "/api.php"

  /// Fetch all available IPSW versions for macOS 12+
  /// - Parameter deviceFilter: Optional device identifier to filter by (e.g., "VirtualMac2,1")
  /// - Returns: Array of IPSW versions matching the filter
  /// - Throws: Network errors, decoding errors, or if URL construction fails
  internal func fetchAllIPSWVersions(deviceFilter: String? = nil) async throws -> [IPSWVersion] {
    // Get list of Mac firmware pages
    let pagesURL = try buildPagesURL()
    let pagesData = try await fetchData(from: pagesURL)
    let pagesResponse = try JSONDecoder().decode(ParseResponse.self, from: pagesData)

    var allVersions: [IPSWVersion] = []

    // Extract firmware page links from content
    let content = pagesResponse.parse.text.content
    let versionPages = try extractVersionPages(from: content)

    // Fetch versions from each page
    for pageTitle in versionPages {
      let pageURL = try buildPageURL(for: pageTitle)
      do {
        let versions = try await parseIPSWPage(url: pageURL, deviceFilter: deviceFilter)
        allVersions.append(contentsOf: versions)
      } catch {
        // Continue on page parse errors - some pages may be empty or malformed
        continue
      }
    }

    guard !allVersions.isEmpty else {
      throw TheAppleWikiError.noDataFound
    }

    return allVersions
  }

  // MARK: - Private Methods

  private func buildPagesURL() throws -> URL {
    guard
      let url = URL(string: baseURL + apiEndpoint + "?action=parse&page=Firmware/Mac&format=json")
    else {
      throw TheAppleWikiError.invalidURL("Firmware/Mac")
    }
    return url
  }

  private func buildPageURL(for pageTitle: String) throws -> URL {
    guard let encoded = pageTitle.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
      let url = URL(string: baseURL + apiEndpoint + "?action=parse&page=\(encoded)&format=json")
    else {
      throw TheAppleWikiError.invalidURL(pageTitle)
    }
    return url
  }

  private func fetchData(from url: URL) async throws -> Data {
    do {
      let (data, _) = try await URLSession.shared.data(from: url)
      return data
    } catch {
      throw TheAppleWikiError.networkError(underlying: error)
    }
  }

  private func extractVersionPages(from content: String) throws -> [String] {
    let pattern = #"Firmware/Mac/(\d+)\.x"#
    guard let regex = try? NSRegularExpression(pattern: pattern) else {
      throw TheAppleWikiError.parsingError("Invalid regex pattern")
    }

    let matches = regex.matches(in: content, range: NSRange(content.startIndex..., in: content))

    let versionPages = matches.compactMap { match -> String? in
      guard let range = Range(match.range(at: 1), in: content),
        let version = Double(content[range]),
        version >= 12
      else {
        return nil
      }
      return "Firmware/Mac/\(Int(version)).x"
    }

    return versionPages
  }

  private func parseIPSWPage(url: URL, deviceFilter: String?) async throws -> [IPSWVersion] {
    let data = try await fetchData(from: url)
    let response = try JSONDecoder().decode(ParseResponse.self, from: data)

    var versions: [IPSWVersion] = []

    // Split content into rows (basic HTML parsing)
    let rows = response.parse.text.content.components(separatedBy: "<tr")

    for row in rows where row.contains("<td") {
      // Extract cell contents
      let cells = row.components(separatedBy: "<td")
        .dropFirst()  // Skip first empty component
        .compactMap { cell -> String? in
          // Extract text between td tags, removing HTML
          guard let endIndex = cell.range(of: "</td>")?.lowerBound
          else {
            return nil
          }
          let content = cell[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines)
          return content.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        }

      guard cells.count >= 6 else { continue }

      let version = cells[0]
      let buildNumber = cells[1]
      let deviceModel = cells[2]
      let fileName = cells[3]

      // Skip if filename doesn't end with ipsw
      guard fileName.lowercased().hasSuffix("ipsw") else { continue }

      // Apply device filter if specified
      if let filter = deviceFilter, !deviceModel.contains(filter) {
        continue
      }

      let fileSize = cells[4]
      let sha1 = cells[5]

      let releaseDate: Date? = cells.count > 6 ? parseDate(cells[6]) : nil
      let url: URL? = parseURL(from: cells[3])

      versions.append(
        IPSWVersion(
          version: version,
          buildNumber: buildNumber,
          deviceModel: deviceModel,
          fileName: fileName,
          fileSize: fileSize,
          sha1: sha1,
          releaseDate: releaseDate,
          url: url
        )
      )
    }

    return versions
  }

  private func parseDate(_ str: String) -> Date? {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter.date(from: str)
  }

  private func parseURL(from text: String) -> URL? {
    // Extract URL from possible HTML link in text
    let pattern = #"href="([^"]+)"#
    guard let match = text.range(of: pattern, options: .regularExpression) else {
      return nil
    }

    let urlString = String(text[match])
      .replacingOccurrences(of: "href=\"", with: "")
      .replacingOccurrences(of: "\"", with: "")

    return URL(string: urlString)
  }
}
