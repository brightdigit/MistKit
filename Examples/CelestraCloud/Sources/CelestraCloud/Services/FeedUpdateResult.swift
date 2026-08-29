//
//  FeedUpdateResult.swift
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
internal import Foundation

/// Result of processing a single feed update
internal enum FeedUpdateResult: Sendable, Equatable {
  // MARK: - Cases

  case success(articlesCreated: Int, articlesUpdated: Int)
  case notModified
  case skipped(reason: String)
  case error(message: String)

  // MARK: - Resolving

  /// Combines article-sync outcomes with the feed-metadata write result.
  ///
  /// Feed-level metadata may still record an RSS fetch as successful
  /// (`failureCount: 0`) even when some article creates/updates failed.
  /// Any article-batch failure turns the overall feed update into `.error`
  /// so callers (and CI with `--update-max-failures 0`) see the outage.
  internal static func resolving(
    syncResult: ArticleSyncResult,
    metadataResult: FeedUpdateResult
  ) -> FeedUpdateResult {
    if syncResult.failureCount > 0 {
      return .error(
        message:
          "Article sync had \(syncResult.failureCount) failures "
          + "(created: \(syncResult.created.failureCount), "
          + "updated: \(syncResult.updated.failureCount))"
      )
    }
    return metadataResult
  }
}
