internal import Foundation
internal import Testing

@testable import MistKit

/// Checking a ``QueryDescriptor`` against a ``CloudKitSchema`` (MistKit #500).
@Suite("Query Validation")
internal enum QueryValidationTests {
  internal typealias Condition = QueryDescriptor.Condition
  internal typealias Sort = QueryDescriptor.Sort

  internal static func player(
    _ conditions: [Condition] = [],
    sorts: [Sort] = []
  ) -> QueryDescriptor {
    QueryDescriptor(recordType: "Player", conditions: conditions, sorts: sorts)
  }

  internal static func match(_ conditions: [Condition]) -> QueryDescriptor {
    QueryDescriptor(recordType: "Match", conditions: conditions)
  }
}
