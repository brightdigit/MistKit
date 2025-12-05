import ArgumentParser
import Foundation
import Logging
import MistKit

struct UpdateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "update",
        abstract: "Fetch and update RSS feeds in CloudKit with web etiquette",
        discussion: """
            Queries feeds from CloudKit (optionally filtered by date and popularity), \
            fetches new articles from each feed, and uploads them to CloudKit. \
            This command demonstrates MistKit's QueryFilter functionality and implements \
            web etiquette best practices including rate limiting, robots.txt checking, \
            and conditional HTTP requests.
            """
    )

    @Option(name: .long, help: "Only update feeds last attempted before this date (ISO8601 format)")
    var lastAttemptedBefore: String?

    @Option(name: .long, help: "Only update feeds with minimum popularity count")
    var minPopularity: Int64?

    @Option(name: .long, help: "Delay between feed fetches in seconds (default: 2.0)")
    var delay: Double = 2.0

    @Flag(name: .long, help: "Skip robots.txt checking (for testing)")
    var skipRobotsCheck: Bool = false

    @Option(name: .long, help: "Skip feeds with failure count above this threshold")
    var maxFailures: Int64?

    @available(macOS 13.0, *)
    func run() async throws {
        print("🔄 Starting feed update...")
        print("   ⏱️  Rate limit: \(delay) seconds between feeds")
        if skipRobotsCheck {
            print("   ⚠️  Skipping robots.txt checks")
        }

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

        // 3. Display failure threshold if provided
        if let maxFail = maxFailures {
            print("   Filter: maximum failures \(maxFail)")
        }

        // 4. Create services
        let service = try CelestraConfig.createCloudKitService()
        let fetcher = RSSFetcherService()
        let robotsService = RobotsTxtService()
        let rateLimiter = RateLimiter(defaultDelay: delay)

        // 5. Query feeds with filters (demonstrates QueryFilter and QuerySort)
        print("📋 Querying feeds...")
        var feeds = try await service.queryFeeds(
            lastAttemptedBefore: cutoffDate,
            minPopularity: minPopularity
        )

        // Filter by failure count if specified
        if let maxFail = maxFailures {
            feeds = feeds.filter { $0.failureCount <= maxFail }
        }

        print("✅ Found \(feeds.count) feed(s) to update")

        // 6. Process each feed
        var successCount = 0
        var errorCount = 0
        var skippedCount = 0
        var notModifiedCount = 0

        for (index, feed) in feeds.enumerated() {
            print("\n[\(index + 1)/\(feeds.count)] 📰 \(feed.title)")

            // Check if feed should be skipped based on minUpdateInterval
            if let minInterval = feed.minUpdateInterval,
               let lastAttempted = feed.lastAttempted {
                let timeSinceLastAttempt = Date().timeIntervalSince(lastAttempted)
                if timeSinceLastAttempt < minInterval {
                    let remainingTime = Int((minInterval - timeSinceLastAttempt) / 60)
                    print("   ⏭️  Skipped (update requested in \(remainingTime) minutes)")
                    skippedCount += 1
                    continue
                }
            }

            // Apply rate limiting
            guard let url = URL(string: feed.feedURL) else {
                print("   ❌ Invalid URL")
                errorCount += 1
                continue
            }

            await rateLimiter.waitIfNeeded(for: url, minimumInterval: feed.minUpdateInterval)

            // Check robots.txt unless skipped
            if !skipRobotsCheck {
                do {
                    let isAllowed = try await robotsService.isAllowed(url)
                    if !isAllowed {
                        print("   🚫 Blocked by robots.txt")
                        skippedCount += 1
                        continue
                    }
                } catch {
                    print("   ⚠️  robots.txt check failed, proceeding anyway: \(error.localizedDescription)")
                }
            }

            // Track attempt - start with existing values
            var totalAttempts = feed.totalAttempts + 1
            var successfulAttempts = feed.successfulAttempts
            var failureCount = feed.failureCount
            var lastFailureReason: String? = feed.lastFailureReason
            var lastModified = feed.lastModified
            var etag = feed.etag
            var minUpdateInterval = feed.minUpdateInterval

            do {
                // Fetch RSS with conditional request support
                let response = try await fetcher.fetchFeed(
                    from: url,
                    lastModified: feed.lastModified,
                    etag: feed.etag
                )

                // Update HTTP metadata
                lastModified = response.lastModified
                etag = response.etag

                // Handle 304 Not Modified
                if !response.wasModified {
                    print("   ✅ Not modified (saved bandwidth)")
                    notModifiedCount += 1
                    successfulAttempts += 1
                    failureCount = 0  // Reset failure count on success
                    lastFailureReason = nil
                } else {
                    guard let feedData = response.feedData else {
                        throw CelestraError.invalidFeedData("No feed data in response")
                    }

                    print("   ✅ Fetched \(feedData.items.count) articles")

                    // Update minUpdateInterval if feed provides one
                    if let interval = feedData.minUpdateInterval {
                        minUpdateInterval = interval
                    }

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

                    successfulAttempts += 1
                    failureCount = 0  // Reset failure count on success
                    lastFailureReason = nil
                }

                successCount += 1

            } catch {
                print("   ❌ Error: \(error.localizedDescription)")
                errorCount += 1
                failureCount += 1
                lastFailureReason = error.localizedDescription
            }

            // Update feed with new metadata
            let updatedFeed = Feed(
                recordName: feed.recordName,
                recordChangeTag: feed.recordChangeTag,
                feedURL: feed.feedURL,
                title: feed.title,
                description: feed.description,
                totalAttempts: totalAttempts,
                successfulAttempts: successfulAttempts,
                usageCount: feed.usageCount,
                lastAttempted: Date(),
                isActive: feed.isActive,
                lastModified: lastModified,
                etag: etag,
                failureCount: failureCount,
                lastFailureReason: lastFailureReason,
                minUpdateInterval: minUpdateInterval
            )

            // Update feed record in CloudKit
            if let recordName = feed.recordName {
                _ = try await service.updateFeed(recordName: recordName, feed: updatedFeed)
            }
        }

        // 7. Print summary
        print("\n✅ Update complete!")
        print("   Success: \(successCount)")
        print("   Not Modified: \(notModifiedCount)")
        print("   Skipped: \(skippedCount)")
        print("   Errors: \(errorCount)")
    }
}
