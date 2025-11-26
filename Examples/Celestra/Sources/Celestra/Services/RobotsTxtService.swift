import Foundation
import Logging

/// Service for fetching and parsing robots.txt files
actor RobotsTxtService {
    private var cache: [String: RobotsRules] = [:]
    private let userAgent: String

    /// Represents parsed robots.txt rules for a domain
    struct RobotsRules {
        let disallowedPaths: [String]
        let crawlDelay: TimeInterval?
        let fetchedAt: Date

        /// Check if a given path is allowed
        func isAllowed(_ path: String) -> Bool {
            // If no disallow rules, everything is allowed
            guard !disallowedPaths.isEmpty else {
                return true
            }

            // Check if path matches any disallow rule
            for disallowedPath in disallowedPaths {
                if path.hasPrefix(disallowedPath) {
                    return false
                }
            }

            return true
        }
    }

    init(userAgent: String = "Celestra") {
        self.userAgent = userAgent
    }

    /// Check if a URL is allowed by robots.txt
    /// - Parameter url: The URL to check
    /// - Returns: True if allowed, false if disallowed
    func isAllowed(_ url: URL) async throws -> Bool {
        guard let host = url.host else {
            // If no host, assume allowed
            return true
        }

        // Get or fetch robots.txt for this domain
        let rules = try await getRules(for: host)

        // Check if the path is allowed
        return rules.isAllowed(url.path)
    }

    /// Get crawl delay for a domain from robots.txt
    /// - Parameter url: The URL to check
    /// - Returns: Crawl delay in seconds, or nil if not specified
    func getCrawlDelay(for url: URL) async throws -> TimeInterval? {
        guard let host = url.host else {
            return nil
        }

        let rules = try await getRules(for: host)
        return rules.crawlDelay
    }

    /// Get or fetch robots.txt rules for a domain
    private func getRules(for host: String) async throws -> RobotsRules {
        // Check cache first (cache for 24 hours)
        if let cached = cache[host],
           Date().timeIntervalSince(cached.fetchedAt) < 86400 {
            return cached
        }

        // Fetch and parse robots.txt
        let rules = try await fetchAndParseRobotsTxt(for: host)
        cache[host] = rules
        return rules
    }

    /// Fetch and parse robots.txt for a domain
    private func fetchAndParseRobotsTxt(for host: String) async throws -> RobotsRules {
        let robotsURL = URL(string: "https://\(host)/robots.txt")!

        do {
            let (data, response) = try await URLSession.shared.data(from: robotsURL)

            guard let httpResponse = response as? HTTPURLResponse else {
                // Default to allow if we can't get a response
                return RobotsRules(disallowedPaths: [], crawlDelay: nil, fetchedAt: Date())
            }

            // If robots.txt doesn't exist, allow everything
            guard httpResponse.statusCode == 200 else {
                return RobotsRules(disallowedPaths: [], crawlDelay: nil, fetchedAt: Date())
            }

            guard let content = String(data: data, encoding: .utf8) else {
                // Can't parse, default to allow
                return RobotsRules(disallowedPaths: [], crawlDelay: nil, fetchedAt: Date())
            }

            return parseRobotsTxt(content)

        } catch {
            // Network error - default to allow (fail open)
            CelestraLogger.rss.warning("⚠️ Failed to fetch robots.txt for \(host): \(error.localizedDescription)")
            return RobotsRules(disallowedPaths: [], crawlDelay: nil, fetchedAt: Date())
        }
    }

    /// Parse robots.txt content
    private func parseRobotsTxt(_ content: String) -> RobotsRules {
        var disallowedPaths: [String] = []
        var crawlDelay: TimeInterval?
        var isRelevantUserAgent = false

        let lines = content.components(separatedBy: .newlines)

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)

            // Skip empty lines and comments
            guard !trimmed.isEmpty, !trimmed.hasPrefix("#") else {
                continue
            }

            // Split on first colon
            let parts = trimmed.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
            guard parts.count == 2 else {
                continue
            }

            let directive = parts[0].trimmingCharacters(in: .whitespaces).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespaces)

            switch directive {
            case "user-agent":
                // Check if this section applies to us
                let agentPattern = value.lowercased()
                isRelevantUserAgent = agentPattern == "*" ||
                                    agentPattern == userAgent.lowercased() ||
                                    agentPattern.contains(userAgent.lowercased())

            case "disallow":
                if isRelevantUserAgent && !value.isEmpty {
                    disallowedPaths.append(value)
                }

            case "crawl-delay":
                if isRelevantUserAgent, let delay = Double(value) {
                    crawlDelay = delay
                }

            default:
                break
            }
        }

        return RobotsRules(
            disallowedPaths: disallowedPaths,
            crawlDelay: crawlDelay,
            fetchedAt: Date()
        )
    }

    /// Clear the robots.txt cache
    func clearCache() {
        cache.removeAll()
    }

    /// Clear cache for a specific domain
    func clearCache(for host: String) {
        cache.removeValue(forKey: host)
    }
}
