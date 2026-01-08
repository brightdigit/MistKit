//
//  FeedMetadataBuilder.swift
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

public import CelestraKit
public import Foundation

/// Pure function type for building feed metadata updates
public struct FeedMetadataBuilder: Sendable {
  /// Initialize feed metadata builder
  public init() {}

  /// Build metadata for successful feed fetch
  /// - Parameters:
  ///   - feedData: Newly fetched feed data
  ///   - response: HTTP fetch response with caching headers
  ///   - feed: Existing feed record
  ///   - totalAttempts: New total attempt count (existing + 1)
  /// - Returns: Metadata update with new feed data and incremented success count
  public func buildSuccessMetadata(
    feedData: FeedData,
    response: FetchResponse,
    feed: Feed,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate {
    FeedMetadataUpdate(
      title: feedData.title,
      description: feedData.description,
      etag: response.etag,
      lastModified: response.lastModified,
      minUpdateInterval: feedData.minUpdateInterval,
      totalAttempts: totalAttempts,
      successfulAttempts: feed.successfulAttempts + 1,
      failureCount: 0  // Reset on success
    )
  }

  /// Build metadata for 304 Not Modified response
  /// - Parameters:
  ///   - feed: Existing feed record
  ///   - response: HTTP fetch response (may have updated caching headers)
  ///   - totalAttempts: New total attempt count (existing + 1)
  /// - Returns: Metadata update preserving old data, updating HTTP headers if present
  public func buildNotModifiedMetadata(
    feed: Feed,
    response: FetchResponse,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate {
    FeedMetadataUpdate(
      title: feed.title,
      description: feed.description,
      etag: response.etag ?? feed.etag,  // Update if provided, else keep existing
      lastModified: response.lastModified ?? feed.lastModified,  // Update if provided
      minUpdateInterval: feed.minUpdateInterval,
      totalAttempts: totalAttempts,
      successfulAttempts: feed.successfulAttempts + 1,  // Still counts as success
      failureCount: 0  // Reset on success
    )
  }

  /// Build metadata for failed feed fetch
  /// - Parameters:
  ///   - feed: Existing feed record
  ///   - totalAttempts: New total attempt count (existing + 1)
  /// - Returns: Metadata update preserving all data, incrementing failure count
  public func buildErrorMetadata(
    feed: Feed,
    totalAttempts: Int64
  ) -> FeedMetadataUpdate {
    FeedMetadataUpdate(
      title: feed.title,
      description: feed.description,
      etag: feed.etag,
      lastModified: feed.lastModified,
      minUpdateInterval: feed.minUpdateInterval,
      totalAttempts: totalAttempts,
      successfulAttempts: feed.successfulAttempts,  // No increment on failure
      failureCount: feed.failureCount + 1
    )
  }
}
