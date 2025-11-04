import Foundation
import SyndiKit

/// Service for fetching and parsing RSS feeds using SyndiKit
@available(macOS 13.0, *)
struct RSSFetcherService {
    struct FeedData {
        let title: String
        let items: [FeedItem]
    }

    struct FeedItem {
        let title: String
        let link: String
        let description: String?
        let author: String?
        let pubDate: Date?
        let guid: String
    }

    /// Fetch and parse RSS feed from URL
    func fetchFeed(from url: URL) async throws -> FeedData {
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
                author: entry.authors.first?.name,
                pubDate: entry.published,
                guid: entry.id.description  // Use id's description as guid
            )
        }

        return FeedData(
            title: feed.title,
            items: items
        )
    }
}
