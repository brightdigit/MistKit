internal import Foundation
internal import Testing

@testable import MistKit

/// A ``Query`` read back from the JSON MistKit sends to CloudKit.
///
/// The tests observe a descriptor's translation at the wire, which is what
/// CloudKit sees.
internal struct WireQuery: Decodable {
  internal struct Filter: Decodable {
    internal var comparator: String
    internal var fieldName: String
    internal var fieldValue: Value
    internal var distance: Double?
  }

  internal struct Value: Decodable {
    internal var value: JSONScalar
    internal var type: String?
  }

  internal struct Sort: Decodable {
    internal var fieldName: String
    internal var ascending: Bool
  }

  internal var recordType: String
  internal var filterBy: [Filter]?
  internal var sortBy: [Sort]?

  internal var filters: [Filter] { filterBy ?? [] }

  internal init(_ query: Query) throws {
    let data = try JSONEncoder().encode(query)
    self = try JSONDecoder().decode(Self.self, from: data)
  }

  /// The single filter one condition becomes.
  internal static func filter(
    _ field: String,
    _ comparator: QueryDescriptor.Comparator,
    _ value: FieldValue
  ) throws -> Filter {
    let descriptor = QueryDescriptor(
      recordType: "Player",
      conditions: [
        QueryDescriptor.Condition(fieldName: field, comparator: comparator, value: value)
      ]
    )
    let wire = try WireQuery(descriptor.query())
    try #require(wire.filters.count == 1)
    return wire.filters[0]
  }
}
