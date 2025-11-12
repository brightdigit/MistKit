import ArgumentParser
import Foundation
import Logging
import MistKit

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Fetch and update RSS feeds in CloudKit",
        discussion: """
            Queries feeds from CloudKit (optionally filtered by date and popularity), \
            fetches new articles from each feed, and uploads them to CloudKit. \
            This command demonstrates MistKit's QueryFilter functionality.
            """
    )

    @Option(name: .long, help: "Only update feeds last attempted before this date (ISO8601 format)")
    var lastAttemptedBefore: String?

    @Option(name: .long, help: "Only update feeds with minimum popularity count")
    var minPopularity: Int64?

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    func run() async throws {
        print("🔄 Starting feed update...")

        // 1. Parse date filter if provided
        var cutoffDate: Date?
        if let dateString = lastAttemptedBefore {
            let formatter = ISO8601DateFormatter()
            guard let date = formatter.date(from: dateString) else {
                throw ValidationError(
                    "Invalid date format. Use ISO8601 (e.g., 2025-01-01T00:00:00Z)"
                )
            }
            cutoffDate = date
            print("   Filter: last attempted before \(formatter.string(from: date))")
        }

        // 2. Display popularity filter if provided
        if let minPop = minPopularity {
            print("   Filter: minimum popularity \(minPop)")
        }

        // 3. Create CloudKit service
        let service = try CelestraConfig.createCloudKitService()

        // 4. Query feeds with filters (demonstrates QueryFilter and QuerySort)
        print("📋 Querying feeds...")
        let feeds = try await service.queryFeeds(
            lastAttemptedBefore: cutoffDate,
            minPopularity: minPopularity
        )

        print("✅ Found \(feeds.count) feed(s) to update")

        // 5. Process each feed
        let fetcher = RSSFetcherService()
        var successCount = 0
        var errorCount = 0

        for (index, feed) in feeds.enumerated() {
            print("\n[\(index + 1)/\(feeds.count)] 📰 \(feed.title)")

            // Track attempt
            var updatedFeed = Feed(
                recordName: feed.recordName,
                recordChangeTag: feed.recordChangeTag,
                feedURL: feed.feedURL,
                title: feed.title,
                description: feed.description,
                totalAttempts: feed.totalAttempts + 1,
                successfulAttempts: feed.successfulAttempts,
                usageCount: feed.usageCount,
                lastAttempted: Date(),
                isActive: feed.isActive
            )

            do {
                // Fetch RSS
                guard let url = URL(string: feed.feedURL) else {
                    print("   ❌ Invalid URL")
                    errorCount += 1
                    continue
                }

                let feedData = try await fetcher.fetchFeed(from: url)
                print("   ✅ Fetched \(feedData.items.count) articles")

                // Convert to PublicArticle
                guard let recordName = feed.recordName else {
                    print("   ❌ No record name")
                    errorCount += 1
                    continue
                }

                let articles = feedData.items.map { item in
                    Article(
                        feed: recordName,
                        title: item.title,
                        link: item.link,
                        description: item.description,
                        content: item.content,
                        author: item.author,
                        pubDate: item.pubDate,
                        guid: item.guid,
                        ttlDays: 30
                    )
                }

                // Duplicate detection and update logic
                if !articles.isEmpty {
                    let guids = articles.map { $0.guid }
                    let existingArticles = try await service.queryArticlesByGUIDs(
                        guids,
                        feedRecordName: recordName
                    )

                    // Create map of existing articles by GUID for fast lookup
                    let existingMap = Dictionary(
                        uniqueKeysWithValues: existingArticles.map { ($0.guid, $0) }
                    )

                    // Separate articles into new vs modified
                    var newArticles: [Article] = []
                    var modifiedArticles: [Article] = []

                    for article in articles {
                        if let existing = existingMap[article.guid] {
                            // Check if content changed
                            if existing.contentHash != article.contentHash {
                                // Content changed - need to update
                                modifiedArticles.append(article.withRecordName(existing.recordName!))
                            }
                            // else: content unchanged - skip
                        } else {
                            // New article
                            newArticles.append(article)
                        }
                    }

                    let unchangedCount = articles.count - newArticles.count - modifiedArticles.count

                    // Upload new articles
                    if !newArticles.isEmpty {
                        let createResult = try await service.createArticles(newArticles)
                        if createResult.isFullSuccess {
                            print("   ✅ Created \(createResult.successCount) new article(s)")
                            CelestraLogger.operations.info("Created \(createResult.successCount) articles for \(feed.title)")
                        } else {
                            print("   ⚠️ Created \(createResult.successCount)/\(createResult.totalProcessed) article(s)")
                            CelestraLogger.errors.warning("Partial create failure: \(createResult.failureCount) failures")
                        }
                    }

                    // Update modified articles
                    if !modifiedArticles.isEmpty {
                        let updateResult = try await service.updateArticles(modifiedArticles)
                        if updateResult.isFullSuccess {
                            print("   🔄 Updated \(updateResult.successCount) modified article(s)")
                            CelestraLogger.operations.info("Updated \(updateResult.successCount) articles for \(feed.title)")
                        } else {
                            print("   ⚠️ Updated \(updateResult.successCount)/\(updateResult.totalProcessed) article(s)")
                            CelestraLogger.errors.warning("Partial update failure: \(updateResult.failureCount) failures")
                        }
                    }

                    // Report unchanged articles
                    if unchangedCount > 0 {
                        print("   ℹ️  Skipped \(unchangedCount) unchanged article(s)")
                    }

                    // Report if nothing to do
                    if newArticles.isEmpty && modifiedArticles.isEmpty {
                        print("   ℹ️  No new or modified articles")
                    }
                }

                // Update success counter
                updatedFeed = Feed(
                    recordName: feed.recordName,
                    recordChangeTag: feed.recordChangeTag,
                    feedURL: feed.feedURL,
                    title: feed.title,
                    description: feed.description,
                    totalAttempts: updatedFeed.totalAttempts,
                    successfulAttempts: feed.successfulAttempts + 1,
                    usageCount: feed.usageCount,
                    lastAttempted: updatedFeed.lastAttempted,
                    isActive: feed.isActive
                )

                successCount += 1

            } catch {
                print("   ❌ Error: \(error.localizedDescription)")
                errorCount += 1
            }

            // Update feed counters
            if let recordName = feed.recordName {
                _ = try await service.updateFeed(recordName: recordName, feed: updatedFeed)
            }
        }

        // 6. Print summary
        print("\n✅ Update complete!")
        print("   Success: \(successCount)")
        print("   Errors: \(errorCount)")
    }
}
