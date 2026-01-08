//
//  AddFeedCommand.swift
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

import CelestraCloudKit
import CelestraKit
import Foundation
import MistKit

// MARK: - Supporting Types

internal struct ExitError: Error {}

// MARK: - Main Type

internal enum AddFeedCommand {
  @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
  internal static func run(args: [String]) async throws {
    guard let feedURL = args.first else {
      print("Error: Missing feed URL")
      print("Usage: celestra-cloud add-feed <url>")
      throw ExitError()
    }

    print("🌐 Fetching RSS feed: \(feedURL)")

    // 1. Validate URL
    guard let url = URL(string: feedURL) else {
      print("Error: Invalid feed URL")
      throw ExitError()
    }

    // 2. Fetch RSS content to validate and extract title
    let fetcher = RSSFetcherService(userAgent: .cloud(build: 1))
    let response = try await fetcher.fetchFeed(from: url)

    guard let feedData = response.feedData else {
      print("Error: Feed was not modified (unexpected)")
      throw ExitError()
    }

    print("✅ Found feed: \(feedData.title)")
    print("   Articles: \(feedData.items.count)")

    // 3. Load configuration and create CloudKit service
    let loader = ConfigurationLoader()
    let config = try await loader.loadConfiguration()
    let validatedCloudKit = try config.cloudkit.validated()
    let service = try CelestraConfig.createCloudKitService(from: validatedCloudKit)

    // 4. Create Feed record with initial metadata
    let feed = Feed(
      feedURL: feedURL,
      title: feedData.title,
      description: feedData.description,
      etag: response.etag,
      lastModified: response.lastModified,
      minUpdateInterval: feedData.minUpdateInterval
    )
    let record = try await service.createFeed(feed)

    print("✅ Feed added to CloudKit")
    print("   Record Name: \(record.recordName)")
  }
}
