internal import Foundation
internal import Testing

@testable import MistKit

/// ``QueryPredicate``: CloudKit's NSPredicate subset as text (MistKit #500).
@Suite("Query Predicate")
internal enum QueryPredicateTests {
  /// Midnight UTC on 1 October 2026.
  internal static let october = Date(timeIntervalSince1970: 1_790_812_800)

  internal static func condition(
    _ field: String,
    _ comparator: QueryDescriptor.Comparator,
    _ value: FieldValue
  ) -> QueryDescriptor.Condition {
    QueryDescriptor.Condition(fieldName: field, comparator: comparator, value: value)
  }

  /// The error parsing `text` throws, or `nil` if it parses.
  internal static func error(_ text: String) -> QueryPredicateParseError? {
    do {
      _ = try QueryPredicate.parse(text)
      return nil
    } catch {
      return error
    }
  }
}
