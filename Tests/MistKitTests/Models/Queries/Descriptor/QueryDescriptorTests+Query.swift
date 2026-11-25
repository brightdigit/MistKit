internal import Foundation
internal import Testing

@testable import MistKit

extension QueryDescriptorTests {
  /// Whole-query translation, `___recordID`, and values that can't be sent.
  @Suite("Query")
  internal struct QueryTranslation {
    internal typealias Condition = QueryDescriptor.Condition

    @Test("___recordID filters with a reference, from a string or a reference")
    internal func recordName() throws {
      let values: [FieldValue] = [
        .string(.value("player-mei")),
        .reference(.value(Reference(recordName: "player-mei"))),
      ]
      for value in values {
        let filter = try WireQuery.filter("___recordID", .equals, value)
        #expect(filter.fieldName == "___recordID")
        #expect(filter.comparator == "EQUALS")
        guard case .object(let object) = filter.fieldValue.value else {
          Issue.record("expected a reference object, got \(filter.fieldValue.value)")
          return
        }
        #expect(object["recordName"] == .string("player-mei"))
      }
    }

    @Test("___recordID IN sends a reference list")
    internal func recordNames() throws {
      let filter = try WireQuery.filter("___recordID", .in, .string(.list(["a", "b"])))
      #expect(filter.comparator == "IN")
      #expect(filter.fieldValue.type == "REFERENCE_LIST")
    }

    @Test("string comparators need a string, NEAR a location")
    internal func valueMismatch() {
      #expect(
        throws: QueryDescriptorError.valueMismatch(fieldName: "rating", comparator: .beginsWith)
      ) {
        try WireQuery.filter("rating", .beginsWith, .int64(.value(1)))
      }
      #expect(throws: QueryDescriptorError.valueMismatch(fieldName: "venue", comparator: .near)) {
        try WireQuery.filter("venue", .near(meters: 1), .string(.value("London")))
      }
    }

    @Test("assets, lists outside IN and scalars inside IN can't be compared")
    internal func unsupportedValues() {
      #expect(throws: QueryDescriptorError.unsupportedValue(fieldName: "avatar")) {
        try WireQuery.filter("avatar", .equals, .asset(.value(Asset(fileChecksum: "c", size: 1))))
      }
      #expect(throws: QueryDescriptorError.unsupportedValue(fieldName: "players")) {
        try WireQuery.filter("players", .equals, .string(.list(["a"])))
      }
      #expect(throws: QueryDescriptorError.unsupportedValue(fieldName: "handle")) {
        try WireQuery.filter("handle", .in, .string(.value("a")))
      }
    }

    @Test("conditions keep their order and sorts their direction")
    internal func wholeQuery() throws {
      let descriptor = QueryDescriptor(
        recordType: "Match",
        conditions: [
          Condition(fieldName: "durationSeconds", comparator: .lessThan, value: .int64(.value(60))),
          Condition(fieldName: "score", comparator: .beginsWith, value: .string(.value("3"))),
        ],
        sorts: [QueryDescriptor.Sort(fieldName: "startedAt", ascending: false)]
      )
      let wire = try WireQuery(descriptor.query())
      #expect(wire.recordType == "Match")
      #expect(wire.filters.map(\.fieldName) == ["durationSeconds", "score"])
      #expect(wire.sortBy?.map(\.fieldName) == ["startedAt"])
      #expect(wire.sortBy?.map(\.ascending) == [false])
    }

    @Test("no conditions sends no filterBy")
    internal func emptyQuery() throws {
      let wire = try WireQuery(QueryDescriptor(recordType: "Player").query())
      #expect(wire.filterBy == nil)
      #expect(wire.sortBy == nil)
    }

    @Test("the descriptor carries zone, limit and desired keys")
    internal func request() throws {
      let descriptor = QueryDescriptor(
        recordType: "Match",
        zoneID: ZoneID(zoneName: "Tournaments", ownerName: "_owner"),
        desiredKeys: ["score", "winner"],
        limit: 50
      )
      #expect(descriptor.zoneID.zoneName == "Tournaments")
      #expect(descriptor.zoneID.ownerName == "_owner")
      #expect(descriptor.limit == 50)
      #expect(descriptor.desiredKeys == ["score", "winner"])
      #expect(try descriptor.query().recordType == "Match")
      #expect(QueryDescriptor(recordType: "Match").limit == CloudKitService.maxRecordsPerRequest)
      #expect(QueryDescriptor(recordType: "Match").zoneID == .defaultZone)
    }
  }
}
