//
//  FeedUpdateProcessor.swift
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

/// Processes individual feed updates
@available(macOS 13.0, *)
internal struct FeedUpdateProcessor {
  internal let service: CloudKitService
  internal let fetcher: RSSFetcherService
  internal let robotsService: RobotsTxtService
  internal let rateLimiter: RateLimiter
  internal let skipRobotsCheck: Bool
  internal let articleSync: ArticleSyncService
  internal let metadataBuilder: FeedMetadataBuilder

  internal init(
    service: CloudKitService,
    fetcher: RSSFetcherService,
    robotsService: RobotsTxtService,
    rateLimiter: RateLimiter,
    skipRobotsCheck: Bool,
    articleSync: ArticleSyncService,
    metadataBuilder: FeedMetadataBuilder = FeedMetadataBuilder()
  ) {
    self.service = service
    self.fetcher = fetcher
    self.robotsService = robotsService
    self.rateLimiter = rateLimiter
    self.skipRobotsCheck = skipRobotsCheck
    self.articleSync = articleSync
    self.metadataBuilder = metadataBuilder
  }

  /// Process a single feed update with comprehensive web etiquette and error handling.
  ///
  /// ## Thread Safety
  ///
  /// This method processes feeds sequentially with no race conditions:
  /// - All `await` operations are chained sequentially (no concurrent execution)
  /// - GUID-based deduplication prevents duplicate article creation
  /// - Each feed operates on isolated data with no shared mutable state
  /// - Rate limiting is managed by the thread-safe `RateLimiter` actor
  ///
  /// Multiple feeds can be processed concurrently by calling this method in parallel,
  /// but each individual feed update is internally sequential and safe.
  ///
  /// - Parameters:
  ///   - feed: The feed to update
  ///   - url: The RSS feed URL to fetch
  /// - Returns: Result indicating success, error, or skipped status
  internal func processFeed(_ feed: Feed, url: URL) async -> FeedUpdateResult {
    guard let recordName = feed.recordName else {
      print("   ❌ Feed missing recordName")
      return .error(message: "Feed missing recordName")
    }

    if !skipRobotsCheck {
      do {
        let isAllowed = try await robotsService.isAllowed(url)
        if !isAllowed {
          print("   ⏭️  Skipped: robots.txt disallows")
          return .skipped(reason: "robots.txt disallows")
        }
      } catch {
        print("   ⚠️  Could not check robots.txt: \(error.localizedDescription)")
      }
    }

    await rateLimiter.waitIfNeeded(for: url)
    return await fetchAndProcess(feed: feed, url: url, recordName: recordName)
  }

  private func fetchAndProcess(
    feed: Feed,
    url: URL,
    recordName: String
  ) async -> FeedUpdateResult {
    let totalAttempts = feed.totalAttempts + 1

    do {
      let response = try await fetcher.fetchFeed(
        from: url,
        lastModified: feed.lastModified,
        etag: feed.etag
      )

      guard let feedData = response.feedData else {
        print("   ℹ️  Not modified (304)")
        let metadata = metadataBuilder.buildNotModifiedMetadata(
          feed: feed,
          response: response,
          totalAttempts: totalAttempts
        )
        _ = await updateFeedMetadata(
          feed: feed,
          recordName: recordName,
          metadata: metadata,
          articlesCreated: 0,
          articlesUpdated: 0
        )
        // For not modified, always return notModified regardless of metadata update result
        return .notModified
      }

      return try await processSuccessfulFetch(
        feed: feed,
        recordName: recordName,
        feedData: feedData,
        response: response,
        totalAttempts: totalAttempts
      )
    } catch {
      print("   ❌ Error: \(error.localizedDescription)")
      let metadata = metadataBuilder.buildErrorMetadata(
        feed: feed,
        totalAttempts: totalAttempts
      )
      _ = await updateFeedMetadata(
        feed: feed,
        recordName: recordName,
        metadata: metadata,
        articlesCreated: 0,
        articlesUpdated: 0
      )
      return .error(message: error.localizedDescription)
    }
  }
}
