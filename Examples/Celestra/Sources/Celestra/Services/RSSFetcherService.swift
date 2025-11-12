import Foundation
import Logging
import SyndiKit

/// Service for fetching and parsing RSS feeds using SyndiKit
@available(macOS 13.0, *)
struct RSSFetcherService {
    /// Retry policy for feed fetch operations
    let retryPolicy: RetryPolicy
    struct FeedData {
        let title: String
        let description: String?
        let items: [FeedItem]
    }

    struct FeedItem {
        let title: String
        let link: String
        let description: String?
        let content: String?
        let author: String?
        let pubDate: Date?
        let guid: String
    }

    /// Initialize with custom retry policy
    /// - Parameter retryPolicy: Retry policy (defaults to .default)
    init(retryPolicy: RetryPolicy = .default) {
        self.retryPolicy = retryPolicy
    }

    /// Fetch and parse RSS feed from URL with retry logic
    func fetchFeed(from url: URL) async throws -> FeedData {
        CelestraLogger.rss.info("📡 Fetching RSS feed from \(url.absoluteString)")

        return try await retryPolicy.execute(
            operation: {
                try await self.fetchFeedInternal(from: url)
            },
            shouldRetry: { error in
                // Retry on network errors, not on parsing errors
                if let celestraError = error as? CelestraError {
                    return celestraError.isRetriable
                }
                // URLSession errors are retriable
                return true
            },
            logger: CelestraLogger.rss
        )
    }

    /// Internal method to fetch and parse RSS feed (without retry)
    private func fetchFeedInternal(from url: URL) async throws -> FeedData {
        do {
            // 1. Fetch RSS XML from URL
            let (data, _) = try await URLSession.shared.data(from: url)

            // 2. Parse feed using SyndiKit
            let decoder = SynDecoder()
            let feed = try decoder.decode(data)

            // 3. Convert Feedable to our FeedData structure
            let items = feed.children.compactMap { entry -> FeedItem? in
                // Get link from url property or use id's description as fallback
                let link: String
                if let url = entry.url {
                    link = url.absoluteString
                } else if case .url(let url) = entry.id {
                    link = url.absoluteString
                } else {
                    // Use id's string representation as fallback
                    link = entry.id.description
                }

                // Skip if link is empty
                guard !link.isEmpty else {
                    return nil
                }

                return FeedItem(
                    title: entry.title,
                    link: link,
                    description: entry.summary,
                    content: entry.contentHtml,
                    author: entry.authors.first?.name,
                    pubDate: entry.published,
                    guid: entry.id.description  // Use id's description as guid
                )
            }

            let feedData = FeedData(
                title: feed.title,
                description: feed.summary,
                items: items
            )

            CelestraLogger.rss.info("✅ Successfully fetched feed: \(feed.title) (\(items.count) items)")
            return feedData
        } catch let error as DecodingError {
            CelestraLogger.errors.error("❌ Failed to parse feed: \(error.localizedDescription)")
            throw CelestraError.invalidFeedData(error.localizedDescription)
        } catch {
            CelestraLogger.errors.error("❌ Failed to fetch feed: \(error.localizedDescription)")
            throw CelestraError.rssFetchFailed(url, underlying: error)
        }
    }
}
