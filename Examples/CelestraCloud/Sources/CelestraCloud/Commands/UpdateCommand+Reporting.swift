//
//  UpdateCommand+Reporting.swift
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
internal import MistKitConfiguration

extension UpdateCommand {
  internal static func createFeedResult(
    feed: Feed,
    result: FeedUpdateResult,
    duration: TimeInterval
  ) -> UpdateReport.FeedResult {
    switch result {
    case .success(let created, let updated):
      return UpdateReport.FeedResult(
        feedURL: feed.feedURL,
        recordName: feed.recordName ?? "unknown",
        status: .success,
        articlesCreated: created,
        articlesUpdated: updated,
        duration: duration,
        error: nil
      )
    case .notModified:
      return UpdateReport.FeedResult(
        feedURL: feed.feedURL,
        recordName: feed.recordName ?? "unknown",
        status: .notModified,
        articlesCreated: 0,
        articlesUpdated: 0,
        duration: duration,
        error: nil
      )
    case .skipped(let reason):
      return UpdateReport.FeedResult(
        feedURL: feed.feedURL,
        recordName: feed.recordName ?? "unknown",
        status: .skipped,
        articlesCreated: 0,
        articlesUpdated: 0,
        duration: duration,
        error: reason
      )
    case .error(let message):
      return UpdateReport.FeedResult(
        feedURL: feed.feedURL,
        recordName: feed.recordName ?? "unknown",
        status: .error,
        articlesCreated: 0,
        articlesUpdated: 0,
        duration: duration,
        error: message
      )
    }
  }

  internal static func writeJSONReport(
    config: CelestraConfiguration,
    summary: UpdateSummary,
    feedResults: [UpdateReport.FeedResult],
    startTime: Date,
    endTime: Date,
    path: String
  ) throws {
    let report = UpdateReport(
      startTime: startTime,
      endTime: endTime,
      configuration: UpdateReport.UpdateConfiguration(
        delay: config.update.delay,
        skipRobotsCheck: config.update.skipRobotsCheck,
        maxFailures: config.update.maxFailures,
        minPopularity: config.update.minPopularity,
        limit: config.update.limit,
        environment: (config.cloudkit.environment ?? "development")
          .lowercased() == "production" ? "production" : "development"
      ),
      summary: UpdateReport.Summary(
        totalFeeds: summary.successCount + summary.errorCount
          + summary.skippedCount + summary.notModifiedCount,
        successCount: summary.successCount,
        errorCount: summary.errorCount,
        skippedCount: summary.skippedCount,
        notModifiedCount: summary.notModifiedCount,
        articlesCreated: summary.articlesCreated,
        articlesUpdated: summary.articlesUpdated
      ),
      feeds: feedResults
    )

    try report.writeJSON(to: path)
    print("📄 JSON report written to: \(path)")
  }

  internal static func printSummary(feeds: [Feed], summary: UpdateSummary) {
    print("\n" + String(repeating: "─", count: 50))
    print("📊 Update Summary")
    print("   Total feeds: \(feeds.count)")
    print("   ✅ Successful: \(summary.successCount)")
    print("   ❌ Errors: \(summary.errorCount)")
    print("   ⏭️  Skipped (robots.txt): \(summary.skippedCount)")
    print("   ℹ️  Not modified (304): \(summary.notModifiedCount)")
    if summary.articlesCreated > 0 || summary.articlesUpdated > 0 {
      print("   📝 Articles created: \(summary.articlesCreated)")
      print("   📝 Articles updated: \(summary.articlesUpdated)")
    }
  }
}
