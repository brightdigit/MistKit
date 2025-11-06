import Foundation

extension Array {
    /// Split array into chunks of specified size
    ///
    /// This utility is used to batch CloudKit operations which have a limit of 200 operations per request.
    ///
    /// - Parameter size: The maximum size of each chunk
    /// - Returns: Array of arrays, each containing at most `size` elements
    public func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}
