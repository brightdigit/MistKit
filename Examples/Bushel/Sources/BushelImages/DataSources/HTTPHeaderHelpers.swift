import Foundation

/// Utilities for fetching HTTP headers from data sources
enum HTTPHeaderHelpers {
    /// Fetches the Last-Modified header from a URL
    /// - Parameter url: The URL to fetch the header from
    /// - Returns: The Last-Modified date, or nil if not available
    static func fetchLastModified(from url: URL) async -> Date? {
        do {
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"

            let (_, response) = try await URLSession.shared.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  let lastModifiedString = httpResponse.value(forHTTPHeaderField: "Last-Modified") else {
                return nil
            }

            return parseLastModifiedDate(from: lastModifiedString)
        } catch {
            BushelLogger.warning("Failed to fetch Last-Modified header from \(url): \(error)", subsystem: BushelLogger.dataSource)
            return nil
        }
    }

    /// Parses a Last-Modified header value in RFC 2822 format
    /// - Parameter dateString: The date string from the header
    /// - Returns: The parsed date, or nil if parsing fails
    private static func parseLastModifiedDate(from dateString: String) -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }
}
