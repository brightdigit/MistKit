import ArgumentParser
import Foundation
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
            var updatedFeed = PublicFeed(
                recordName: feed.recordName,
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
                    PublicArticle(
                        feedRecordName: recordName,
                        title: item.title,
                        link: item.link,
                        description: item.description,
                        author: item.author,
                        pubDate: item.pubDate,
                        guid: item.guid,
                        ttlDays: 30
                    )
                }

                // Duplicate detection: query existing articles by GUID
                if !articles.isEmpty {
                    let guids = articles.map { $0.guid }
                    let existingArticles = try await service.queryArticlesByGUIDs(
                        guids,
                        feedRecordName: recordName
                    )

                    // Create set of existing GUIDs for fast lookup
                    let existingGUIDs = Set(existingArticles.map { $0.guid })

                    // Filter out duplicates
                    let newArticles = articles.filter { !existingGUIDs.contains($0.guid) }

                    let duplicateCount = articles.count - newArticles.count

                    if duplicateCount > 0 {
                        print("   ℹ️  Skipped \(duplicateCount) duplicate(s)")
                    }

                    // Upload only new articles
                    if !newArticles.isEmpty {
                        _ = try await service.createArticles(newArticles)
                        print("   ✅ Uploaded \(newArticles.count) new article(s)")
                    } else {
                        print("   ℹ️  No new articles to upload")
                    }
                }

                // Update success counter
                updatedFeed = PublicFeed(
                    recordName: feed.recordName,
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
