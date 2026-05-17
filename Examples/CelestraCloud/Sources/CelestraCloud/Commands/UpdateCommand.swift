//
//  UpdateCommand.swift
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

import CelestraCloudKit
import CelestraKit
import Foundation
import MistKit

internal enum UpdateCommand {
  @available(macOS 13.0, *)
  internal static func run() async throws {
    let startTime = Date()
    let loader = ConfigurationLoader()
    let config = try await loader.loadConfiguration()

    printStartupInfo(config: config)

    let processor = try createProcessor(config: config)
    let feeds = try await queryFeeds(config: config, processor: processor)

    print("✅ Found \(feeds.count) feed(s) to update")

    let (summary, feedResults) = await processFeeds(feeds, processor: processor)
    let endTime = Date()

    printSummary(feeds: feeds, summary: summary)

    // Write JSON report if configured
    if let jsonPath = config.update.jsonOutputPath {
      try writeJSONReport(
        config: config,
        summary: summary,
        feedResults: feedResults,
        startTime: startTime,
        endTime: endTime,
        path: jsonPath
      )
    }

    // Fail if any errors occurred
    if summary.errorCount > 0 {
      throw UpdateCommandError(errorCount: summary.errorCount)
    }
  }

  private static func printStartupInfo(config: CelestraConfiguration) {
    print("🔄 Starting feed update...")
    print("   ⏱️  Rate limit: \(config.update.delay) seconds between feeds")
    if config.update.skipRobotsCheck {
      print("   ⚠️  Skipping robots.txt checks")
    }

    if let date = config.update.lastAttemptedBefore {
      let formatter = ISO8601DateFormatter()
      print("   Filter: last attempted before \(formatter.string(from: date))")
    }
    if let minPop = config.update.minPopularity {
      print("   Filter: minimum popularity \(minPop)")
    }
    if let maxFail = config.update.maxFailures {
      print("   Filter: maximum failures \(maxFail)")
    }
    if let limit = config.update.limit {
      print("   Limit: maximum \(limit) feeds")
    }
  }

  @available(macOS 13.0, *)
  private static func createProcessor(
    config: CelestraConfiguration
  ) throws -> FeedUpdateProcessor {
    let validatedCloudKit = try config.cloudkit.validated()
    let service = try CelestraConfig.createCloudKitService(from: validatedCloudKit)
    let fetcher = RSSFetcherService(userAgent: .cloud(build: 1))
    let robotsService = RobotsTxtService(userAgent: .cloud(build: 1))
    let rateLimiter = RateLimiter(defaultDelay: config.update.delay)

    // Create ArticleSyncService
    let articleService = ArticleCloudKitService(recordOperator: service)
    let articleSync = ArticleSyncService(articleService: articleService)

    return FeedUpdateProcessor(
      service: service,
      fetcher: fetcher,
      robotsService: robotsService,
      rateLimiter: rateLimiter,
      skipRobotsCheck: config.update.skipRobotsCheck,
      articleSync: articleSync
    )
  }

  @available(macOS 13.0, *)
  private static func queryFeeds(
    config: CelestraConfiguration,
    processor: FeedUpdateProcessor
  ) async throws -> [Feed] {
    print("📋 Querying feeds...")

    var feeds = try await processor.service.queryFeeds(
      lastAttemptedBefore: config.update.lastAttemptedBefore,
      minPopularity: config.update.minPopularity
    )

    if let maxFail = config.update.maxFailures {
      feeds = feeds.filter { $0.failureCount <= maxFail }
    }

    if let limit = config.update.limit {
      feeds = Array(feeds.prefix(limit))
    }

    return feeds
  }

  @available(macOS 13.0, *)
  private static func processFeeds(
    _ feeds: [Feed],
    processor: FeedUpdateProcessor
  ) async -> (UpdateSummary, [UpdateReport.FeedResult]) {
    var summary = UpdateSummary()
    var feedResults: [UpdateReport.FeedResult] = []

    for (index, feed) in feeds.enumerated() {
      print("\n[\(index + 1)/\(feeds.count)] Updating: \(feed.title)")
      print("   URL: \(feed.feedURL)")

      let feedStartTime = Date()

      guard let url = URL(string: feed.feedURL) else {
        print("   ❌ Invalid URL")
        summary.errorCount += 1
        feedResults.append(
          UpdateReport.FeedResult(
            feedURL: feed.feedURL,
            recordName: feed.recordName ?? "unknown",
            status: .error,
            articlesCreated: 0,
            articlesUpdated: 0,
            duration: Date().timeIntervalSince(feedStartTime),
            error: "Invalid URL"
          )
        )
        continue
      }

      let result = await processor.processFeed(feed, url: url)
      summary.record(result)

      let feedEndTime = Date()
      let feedResult = createFeedResult(
        feed: feed,
        result: result,
        duration: feedEndTime.timeIntervalSince(feedStartTime)
      )
      feedResults.append(feedResult)
    }

    return (summary, feedResults)
  }
}
