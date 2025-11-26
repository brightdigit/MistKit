import Foundation

/// Protocol for data source fetchers that retrieve records from external APIs
///
/// This protocol provides a common interface for all data source fetchers in the Bushel pipeline.
/// Fetchers are responsible for retrieving data from external sources and converting them to
/// typed record models.
///
/// ## Implementation Requirements
/// - Must be `Sendable` to support concurrent fetching
/// - Should use `HTTPHeaderHelpers.fetchLastModified()` when available to track source freshness
/// - Should log warnings for missing or malformed data using `BushelLogger.dataSource`
/// - Should handle network errors gracefully and provide meaningful error messages
///
/// ## Example Implementation
/// ```swift
/// struct MyFetcher: DataSourceFetcher {
///     func fetch() async throws -> [MyRecord] {
///         let url = URL(string: "https://api.example.com/data")!
///         let (data, _) = try await URLSession.shared.data(from: url)
///         let items = try JSONDecoder().decode([Item].self, from: data)
///         return items.map { MyRecord(from: $0) }
///     }
/// }
/// ```
protocol DataSourceFetcher: Sendable {
    /// The type of records this fetcher produces
    associatedtype Record

    /// Fetch records from the external data source
    ///
    /// - Returns: Collection of records fetched from the source
    /// - Throws: Errors related to network requests, parsing, or data validation
    func fetch() async throws -> Record
}

/// Common utilities for data source fetchers
enum DataSourceUtilities {
    /// Fetch data from a URL with optional Last-Modified header tracking
    ///
    /// This helper combines data fetching with Last-Modified header extraction,
    /// allowing fetchers to track when their source data was last updated.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch from
    ///   - trackLastModified: Whether to make a HEAD request to get Last-Modified (default: true)
    /// - Returns: Tuple of (data, lastModified date or nil)
    /// - Throws: Errors from URLSession or network issues
    static func fetchData(
        from url: URL,
        trackLastModified: Bool = true
    ) async throws -> (Data, Date?) {
        let lastModified = trackLastModified ? await HTTPHeaderHelpers.fetchLastModified(from: url) : nil
        let (data, _) = try await URLSession.shared.data(from: url)
        return (data, lastModified)
    }

    /// Decode JSON data with helpful error logging
    ///
    /// - Parameters:
    ///   - type: The type to decode to
    ///   - data: The JSON data to decode
    ///   - source: Source name for error logging
    /// - Returns: Decoded object
    /// - Throws: DecodingError with context
    static func decodeJSON<T: Decodable>(
        _ type: T.Type,
        from data: Data,
        source: String
    ) throws -> T {
        do {
            return try JSONDecoder().decode(type, from: data)
        } catch {
            BushelLogger.warning(
                "Failed to decode \(T.self) from \(source): \(error)",
                subsystem: BushelLogger.dataSource
            )
            throw error
        }
    }
}
