//
//  VirtualBuddyFetcher.swift
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
import BushelUtilities
import BushelVirtualBuddy
import Foundation

#if canImport(FoundationNetworking)
  import FoundationNetworking
#endif

/// Fetcher for enriching restore images with VirtualBuddy TSS signing status
internal struct VirtualBuddyFetcher: DataSourceFetcher, Sendable {
  internal typealias Record = [RestoreImageRecord]

  /// Base URL components for VirtualBuddy TSS API endpoint
  // swiftlint:disable:next force_unwrapping
  private static let baseURLComponents = URLComponents(
    string: "https://tss.virtualbuddy.app/v1/status"
  )!

  private let apiKey: String
  private let decoder: JSONDecoder
  private let urlSession: URLSession

  /// Failable initializer that reads API key from environment variable
  internal init?() {
    guard let key = ProcessInfo.processInfo.environment["VIRTUALBUDDY_API_KEY"], !key.isEmpty else {
      return nil
    }
    self.init(apiKey: key)
  }

  /// Explicit initializer with API key
  internal init(
    apiKey: String,
    decoder: JSONDecoder = JSONDecoder(),
    urlSession: URLSession = .shared
  ) {
    self.apiKey = apiKey
    self.decoder = decoder
    self.urlSession = urlSession
  }

  /// DataSourceFetcher protocol requirement - returns empty for enrichment fetchers
  internal func fetch() async throws -> [RestoreImageRecord] {
    []
  }

  /// Enrich existing restore images with VirtualBuddy TSS signing status
  internal func fetch(existingImages: [RestoreImageRecord]) async throws -> [RestoreImageRecord] {
    var enrichedImages: [RestoreImageRecord] = []

    // Count images that need VirtualBuddy checking (non-file URLs)
    let imagesToCheck = existingImages.filter { $0.downloadURL.scheme != "file" }
    let totalCount = imagesToCheck.count
    var processedCount = 0

    for image in existingImages {
      // Skip file URLs (VirtualBuddy API doesn't support them)
      guard image.downloadURL.scheme != "file" else {
        enrichedImages.append(image)
        continue
      }

      processedCount += 1

      do {
        let response = try await checkSigningStatus(for: image.downloadURL)

        // Validate build number matches
        guard response.build == image.buildNumber else {
          print(
            "   ⚠️  VirtualBuddy: \(image.buildNumber) - build mismatch: "
              + "expected \(image.buildNumber), got \(response.build) (\(processedCount)/\(totalCount))"
          )
          enrichedImages.append(image)
          continue
        }

        // Create enriched record with VirtualBuddy data
        var enriched = image
        enriched.isSigned = response.isSigned
        enriched.source = "tss.virtualbuddy.app"
        enriched.sourceUpdatedAt = Date()  // Real-time TSS check
        enriched.notes = response.message  // TSS status message

        // Show result with signing status
        let statusEmoji = response.isSigned ? "✅" : "❌"
        let statusText = response.isSigned ? "signed" : "unsigned"
        print(
          "   \(statusEmoji) VirtualBuddy: \(image.buildNumber) - "
            + "\(statusText) (\(processedCount)/\(totalCount))"
        )

        enrichedImages.append(enriched)
      } catch {
        print(
          "   ⚠️  VirtualBuddy: \(image.buildNumber) - error: \(error) (\(processedCount)/\(totalCount))"
        )
        enrichedImages.append(image)  // Keep original on error
      }

      // Add random delay between requests to respect rate limit (2 req/5 sec)
      // Only delay if there are more images to process
      if processedCount < totalCount {
        let randomDelay = Double.random(in: 2.5...3.5)
        try await Task.sleep(for: .seconds(randomDelay), tolerance: .seconds(1))
      }
    }

    return enrichedImages
  }

  /// Check signing status for an IPSW URL using VirtualBuddy TSS API
  private func checkSigningStatus(for ipswURL: URL) async throws -> VirtualBuddySig {
    // Build endpoint URL with API key and IPSW URL
    var components = Self.baseURLComponents
    components.queryItems = [
      URLQueryItem(name: "apiKey", value: apiKey),
      URLQueryItem(name: "ipsw", value: ipswURL.absoluteString),
    ]

    guard let endpointURL = components.url else {
      throw VirtualBuddyFetcherError.invalidURL
    }

    // Fetch data from API
    let data: Data
    let response: URLResponse
    do {
      (data, response) = try await urlSession.data(from: endpointURL)
    } catch {
      throw VirtualBuddyFetcherError.networkError(error)
    }

    // Check HTTP status
    if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
      throw VirtualBuddyFetcherError.httpError(httpResponse.statusCode)
    }

    // Decode response
    do {
      return try decoder.decode(VirtualBuddySig.self, from: data)
    } catch {
      throw VirtualBuddyFetcherError.decodingError(error)
    }
  }
}

/// Errors that can occur during VirtualBuddy fetching
internal enum VirtualBuddyFetcherError: Error {
  case invalidURL
  case networkError(any Error)
  case httpError(Int)
  case decodingError(any Error)
}
