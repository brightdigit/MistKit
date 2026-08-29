//
//  FeedUpdateProcessor+Fetch.swift
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

internal import CelestraCloudKit
internal import CelestraKit
internal import Foundation
internal import MistKit

extension FeedUpdateProcessor {
  internal func processSuccessfulFetch(
    feed: Feed,
    recordName: String,
    feedData: FeedData,
    response: FetchResponse,
    totalAttempts: Int64
  ) async throws -> FeedUpdateResult {
    print("   ✅ Fetched: \(feedData.items.count) articles")

    // Sync articles via ArticleSyncService
    let syncResult = try await articleSync.syncArticles(
      items: feedData.items,
      feedRecordName: recordName
    )

    // Print results for user feedback
    print("   📝 New: \(syncResult.newCount), Modified: \(syncResult.modifiedCount)")
    if syncResult.created.failureCount > 0 {
      print("   ⚠️  Failed to create \(syncResult.created.failureCount) articles")
    }
    if syncResult.updated.failureCount > 0 {
      print("   ⚠️  Failed to update \(syncResult.updated.failureCount) articles")
    }

    let metadata = metadataBuilder.buildSuccessMetadata(
      feedData: feedData,
      response: response,
      feed: feed,
      totalAttempts: totalAttempts
    )
    let metadataResult = await updateFeedMetadata(
      feed: feed,
      recordName: recordName,
      metadata: metadata,
      articlesCreated: syncResult.created.successCount,
      articlesUpdated: syncResult.updated.successCount
    )
    return FeedUpdateResult.resolving(
      syncResult: syncResult,
      metadataResult: metadataResult
    )
  }

  internal func updateFeedMetadata(
    feed: Feed,
    recordName: String,
    metadata: FeedMetadataUpdate,
    articlesCreated: Int,
    articlesUpdated: Int
  ) async -> FeedUpdateResult {
    let updatedFeed = Feed(
      recordName: feed.recordName,
      recordChangeTag: feed.recordChangeTag,
      feedURL: feed.feedURL,
      title: metadata.title,
      description: metadata.description,
      isFeatured: feed.isFeatured,
      isVerified: feed.isVerified,
      subscriberCount: feed.subscriberCount,
      totalAttempts: metadata.totalAttempts,
      successfulAttempts: metadata.successfulAttempts,
      lastAttempted: Date(),
      isActive: feed.isActive,
      etag: metadata.etag,
      lastModified: metadata.lastModified,
      failureCount: metadata.failureCount,
      minUpdateInterval: metadata.minUpdateInterval
    )
    do {
      _ = try await service.updateFeed(recordName: recordName, feed: updatedFeed)
      return metadata.failureCount == 0
        ? .success(articlesCreated: articlesCreated, articlesUpdated: articlesUpdated)
        : .error(message: "Feed update had failures")
    } catch {
      print("   ⚠️  Failed to update feed metadata: \(error.localizedDescription)")
      return .error(message: "Failed to update feed metadata: \(error.localizedDescription)")
    }
  }
}
