import ArgumentParser
import Foundation
import MistKit

struct AddFeedCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "add-feed",
        abstract: "Add a new RSS feed to CloudKit",
        discussion: """
            Fetches the RSS feed to validate it and extract metadata, then creates a \
            Feed record in CloudKit's public database.
            """
    )

    @Argument(help: "RSS feed URL")
    var feedURL: String

    @available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *)
    func run() async throws {
        print("🌐 Fetching RSS feed: \(feedURL)")

        // 1. Validate URL
        guard let url = URL(string: feedURL) else {
            throw ValidationError("Invalid feed URL")
        }

        // 2. Fetch RSS content to validate and extract title
        let fetcher = RSSFetcherService()
        let response = try await fetcher.fetchFeed(from: url)

        guard let feedData = response.feedData else {
            throw ValidationError("Feed was not modified (unexpected)")
        }

        print("✅ Found feed: \(feedData.title)")
        print("   Articles: \(feedData.items.count)")

        // 3. Create CloudKit service
        let service = try CelestraConfig.createCloudKitService()

        // 4. Create Feed record with initial metadata
        let feed = Feed(
            feedURL: feedURL,
            title: feedData.title,
            description: feedData.description,
            lastModified: response.lastModified,
            etag: response.etag,
            minUpdateInterval: feedData.minUpdateInterval
        )
        let record = try await service.createFeed(feed)

        print("✅ Feed added to CloudKit")
        print("   Record Name: \(record.recordName)")
    }
}
