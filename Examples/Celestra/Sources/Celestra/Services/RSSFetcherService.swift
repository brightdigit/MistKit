import Foundation
import Logging
import SyndiKit

/// Service for fetching and parsing RSS feeds using SyndiKit with web etiquette
@available(macOS 13.0, *)
struct RSSFetcherService {
    private let urlSession: URLSession
    private let userAgent: String

    struct FeedData {
        let title: String
        let description: String?
        let items: [FeedItem]
        let minUpdateInterval: TimeInterval?  // Parsed from <ttl> or <updatePeriod>
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

    struct FetchResponse {
        let feedData: FeedData?  // nil if 304 Not Modified
        let lastModified: String?
        let etag: String?
        let wasModified: Bool
    }

    init(userAgent: String = "Celestra/1.0 (MistKit RSS Reader; +https://github.com/brightdigit/MistKit)") {
        self.userAgent = userAgent

        // Create custom URLSession with proper configuration
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = [
            "User-Agent": userAgent,
            "Accept": "application/rss+xml, application/atom+xml, application/xml;q=0.9, text/xml;q=0.8, */*;q=0.7"
        ]

        self.urlSession = URLSession(configuration: configuration)
    }

    /// Fetch and parse RSS feed from URL with conditional request support
    /// - Parameters:
    ///   - url: Feed URL to fetch
    ///   - lastModified: Optional Last-Modified header from previous fetch
    ///   - etag: Optional ETag header from previous fetch
    /// - Returns: Fetch response with feed data and HTTP metadata
    func fetchFeed(
        from url: URL,
        lastModified: String? = nil,
        etag: String? = nil
    ) async throws -> FetchResponse {
        CelestraLogger.rss.info("📡 Fetching RSS feed from \(url.absoluteString)")

        // Build request with conditional headers
        var request = URLRequest(url: url)
        if let lastModified = lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }
        if let etag = etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }

        do {
            // 1. Fetch RSS XML from URL
            let (data, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw CelestraError.invalidFeedData("Non-HTTP response")
            }

            // Extract response headers
            let responseLastModified = httpResponse.value(forHTTPHeaderField: "Last-Modified")
            let responseEtag = httpResponse.value(forHTTPHeaderField: "ETag")

            // Handle 304 Not Modified
            if httpResponse.statusCode == 304 {
                CelestraLogger.rss.info("✅ Feed not modified (304)")
                return FetchResponse(
                    feedData: nil,
                    lastModified: responseLastModified ?? lastModified,
                    etag: responseEtag ?? etag,
                    wasModified: false
                )
            }

            // Check for error status codes
            guard (200...299).contains(httpResponse.statusCode) else {
                throw CelestraError.rssFetchFailed(url, underlying: URLError(.badServerResponse))
            }

            // 2. Parse feed using SyndiKit
            let decoder = SynDecoder()
            let feed = try decoder.decode(data)

            // 3. Parse RSS metadata for update intervals
            let minUpdateInterval = parseUpdateInterval(from: feed)

            // 4. Convert Feedable to our FeedData structure
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
                items: items,
                minUpdateInterval: minUpdateInterval
            )

            CelestraLogger.rss.info("✅ Successfully fetched feed: \(feed.title) (\(items.count) items)")
            if let interval = minUpdateInterval {
                CelestraLogger.rss.info("   📅 Feed requests updates every \(Int(interval / 60)) minutes")
            }

            return FetchResponse(
                feedData: feedData,
                lastModified: responseLastModified,
                etag: responseEtag,
                wasModified: true
            )

        } catch let error as DecodingError {
            CelestraLogger.errors.error("❌ Failed to parse feed: \(error.localizedDescription)")
            throw CelestraError.invalidFeedData(error.localizedDescription)
        } catch {
            CelestraLogger.errors.error("❌ Failed to fetch feed: \(error.localizedDescription)")
            throw CelestraError.rssFetchFailed(url, underlying: error)
        }
    }

    /// Parse minimum update interval from RSS feed metadata
    /// - Parameter feed: Parsed feed from SyndiKit
    /// - Returns: Minimum update interval in seconds, or nil if not specified
    private func parseUpdateInterval(from feed: Feedable) -> TimeInterval? {
        // Try to access raw XML for custom elements
        // SyndiKit may not expose all RSS extensions directly

        // For now, we'll use a simple heuristic:
        // - If feed has <ttl> tag (in minutes), use that
        // - If feed has <sy:updatePeriod> and <sy:updateFrequency> (Syndication module), use that
        // - Otherwise, default to nil (no preference)

        // Note: SyndiKit's Feedable protocol doesn't expose these directly,
        // so we'd need to access the raw XML or extend SyndiKit
        // For this implementation, we'll parse common values if available

        // Default: no specific interval (1 hour minimum is reasonable)
        // This could be enhanced by parsing the raw XML data
        return nil  // TODO: Implement RSS <ttl> and <sy:*> parsing if needed
    }
}
