//  FetchConfiguration.swift
//  Created by Claude Code

import Foundation

/// Configuration for data source fetch throttling
internal struct FetchConfiguration: Codable, Sendable {
    // MARK: - Properties

    /// Global minimum interval between fetches (applies to all sources unless overridden)
    let globalMinimumFetchInterval: TimeInterval?

    /// Per-source minimum intervals (overrides global and default intervals)
    /// Key is the source name (e.g., "appledb.dev", "ipsw.me")
    let perSourceIntervals: [String: TimeInterval]

    /// Whether to use default intervals for known sources
    let useDefaults: Bool

    // MARK: - Initialization

    init(
        globalMinimumFetchInterval: TimeInterval? = nil,
        perSourceIntervals: [String: TimeInterval] = [:],
        useDefaults: Bool = true
    ) {
        self.globalMinimumFetchInterval = globalMinimumFetchInterval
        self.perSourceIntervals = perSourceIntervals
        self.useDefaults = useDefaults
    }

    // MARK: - Methods

    /// Get the minimum fetch interval for a specific source
    /// - Parameter source: The source name (e.g., "appledb.dev")
    /// - Returns: The minimum interval in seconds, or nil if no restrictions
    func minimumInterval(for source: String) -> TimeInterval? {
        // Priority: per-source > global > defaults
        if let perSourceInterval = perSourceIntervals[source] {
            return perSourceInterval
        }

        if let globalInterval = globalMinimumFetchInterval {
            return globalInterval
        }

        if useDefaults {
            return Self.defaultIntervals[source]
        }

        return nil
    }

    /// Should this source be fetched given the last fetch time?
    /// - Parameters:
    ///   - source: The source name
    ///   - lastFetchedAt: When the source was last fetched (nil means never fetched)
    ///   - force: Whether to ignore intervals and fetch anyway
    /// - Returns: True if the source should be fetched
    func shouldFetch(
        source: String,
        lastFetchedAt: Date?,
        force: Bool = false
    ) -> Bool {
        // Always fetch if force flag is set
        if force { return true }

        // Always fetch if never fetched before
        guard let lastFetch = lastFetchedAt else { return true }

        // Check if enough time has passed since last fetch
        guard let minInterval = minimumInterval(for: source) else { return true }

        let timeSinceLastFetch = Date().timeIntervalSince(lastFetch)
        return timeSinceLastFetch >= minInterval
    }

    // MARK: - Default Intervals

    /// Default minimum intervals for known sources (in seconds)
    static let defaultIntervals: [String: TimeInterval] = [
        // Restore Image Sources
        "appledb.dev": 6 * 3600, // 6 hours - frequently updated
        "ipsw.me": 12 * 3600, // 12 hours - less frequent updates
        "mesu.apple.com": 1 * 3600, // 1 hour - signing status changes frequently
        "mrmacintosh.com": 12 * 3600, // 12 hours - manual updates
        "theapplewiki.com": 24 * 3600, // 24 hours - deprecated, rarely updated

        // Version Sources
        "xcodereleases.com": 12 * 3600, // 12 hours - Xcode releases
        "swiftversion.net": 12 * 3600, // 12 hours - Swift releases
    ]

    // MARK: - Factory Methods

    /// Load configuration from environment variables
    /// - Returns: Configuration with values from environment, or defaults
    static func loadFromEnvironment() -> FetchConfiguration {
        var perSourceIntervals: [String: TimeInterval] = [:]

        // Check for per-source environment variables (e.g., BUSHEL_FETCH_INTERVAL_APPLEDB)
        for (source, _) in defaultIntervals {
            let envKey = "BUSHEL_FETCH_INTERVAL_\(source.uppercased().replacingOccurrences(of: ".", with: "_"))"
            if let intervalString = ProcessInfo.processInfo.environment[envKey],
               let interval = TimeInterval(intervalString)
            {
                perSourceIntervals[source] = interval
            }
        }

        // Check for global interval
        let globalInterval = ProcessInfo.processInfo.environment["BUSHEL_FETCH_INTERVAL_GLOBAL"]
            .flatMap { TimeInterval($0) }

        return FetchConfiguration(
            globalMinimumFetchInterval: globalInterval,
            perSourceIntervals: perSourceIntervals,
            useDefaults: true
        )
    }
}
