import Foundation

/// Actor-based rate limiter for RSS feed fetching
actor RateLimiter {
    private var lastFetchTimes: [String: Date] = [:]
    private let defaultDelay: TimeInterval
    private let perDomainDelay: TimeInterval

    /// Initialize rate limiter with configurable delays
    /// - Parameters:
    ///   - defaultDelay: Default delay between any two feed fetches (seconds)
    ///   - perDomainDelay: Additional delay when fetching from the same domain (seconds)
    init(defaultDelay: TimeInterval = 2.0, perDomainDelay: TimeInterval = 5.0) {
        self.defaultDelay = defaultDelay
        self.perDomainDelay = perDomainDelay
    }

    /// Wait if necessary before fetching a URL
    /// - Parameters:
    ///   - url: The URL to fetch
    ///   - minimumInterval: Optional minimum interval to respect (e.g., from RSS <ttl>)
    func waitIfNeeded(for url: URL, minimumInterval: TimeInterval? = nil) async {
        guard let host = url.host else {
            return
        }

        let now = Date()
        let key = host

        // Determine the required delay
        var requiredDelay = defaultDelay

        // Use per-domain delay if we've fetched from this domain before
        if let lastFetch = lastFetchTimes[key] {
            requiredDelay = max(requiredDelay, perDomainDelay)

            // If feed specifies minimum interval, respect it
            if let minInterval = minimumInterval {
                requiredDelay = max(requiredDelay, minInterval)
            }

            let timeSinceLastFetch = now.timeIntervalSince(lastFetch)
            let remainingDelay = requiredDelay - timeSinceLastFetch

            if remainingDelay > 0 {
                let nanoseconds = UInt64(remainingDelay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        }

        // Record this fetch time
        lastFetchTimes[key] = Date()
    }

    /// Wait with a global delay (between any two fetches, regardless of domain)
    func waitGlobal() async {
        // Get the most recent fetch time across all domains
        if let mostRecent = lastFetchTimes.values.max() {
            let timeSinceLastFetch = Date().timeIntervalSince(mostRecent)
            let remainingDelay = defaultDelay - timeSinceLastFetch

            if remainingDelay > 0 {
                let nanoseconds = UInt64(remainingDelay * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanoseconds)
            }
        }
    }

    /// Clear all rate limiting history
    func reset() {
        lastFetchTimes.removeAll()
    }

    /// Clear rate limiting history for a specific domain
    func reset(for host: String) {
        lastFetchTimes.removeValue(forKey: host)
    }
}
