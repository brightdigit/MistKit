internal import Foundation
internal import Testing

@testable import MistKit

extension QueryDescriptorTests {
  /// One test per comparator × type. Expected comparator names are CloudKit
  /// Web Services' (`EQUALS`, `BEGINS_WITH`, `LIST_CONTAINS`, …).
  @Suite("Translation")
  internal struct Translation {
    internal typealias Comparator = QueryDescriptor.Comparator

    internal static let ordered: [(Comparator, String)] = [
      (.equals, "EQUALS"),
      (.notEquals, "NOT_EQUALS"),
      (.lessThan, "LESS_THAN"),
      (.lessThanOrEquals, "LESS_THAN_OR_EQUALS"),
      (.greaterThan, "GREATER_THAN"),
      (.greaterThanOrEquals, "GREATER_THAN_OR_EQUALS"),
    ]

    internal static let strings: [(Comparator, String)] = [
      (.equals, "EQUALS"),
      (.notEquals, "NOT_EQUALS"),
      (.beginsWith, "BEGINS_WITH"),
      (.notBeginsWith, "NOT_BEGINS_WITH"),
      (.containsAllTokens, "CONTAINS_ALL_TOKENS"),
      (.containsAnyTokens, "CONTAINS_ANY_TOKENS"),
    ]

    @Test("INT64", arguments: ordered)
    internal func int64(comparator: Comparator, wire: String) throws {
      let filter = try WireQuery.filter("rating", comparator, .int64(.value(1_500)))
      #expect(filter.comparator == wire)
      #expect(filter.fieldName == "rating")
      #expect(filter.fieldValue.value == .number(1_500))
    }

    @Test("DOUBLE", arguments: ordered)
    internal func double(comparator: Comparator, wire: String) throws {
      let filter = try WireQuery.filter("score", comparator, .double(.value(2.5)))
      #expect(filter.comparator == wire)
      #expect(filter.fieldValue.value == .number(2.5))
    }

    @Test("TIMESTAMP is sent in milliseconds", arguments: ordered)
    internal func timestamp(comparator: Comparator, wire: String) throws {
      // 2026-10-01T00:00:00Z
      let date = Date(timeIntervalSince1970: 1_790_812_800)
      let filter = try WireQuery.filter("startedAt", comparator, .date(.value(date)))
      #expect(filter.comparator == wire)
      #expect(filter.fieldValue.value == .number(1_790_812_800_000))
    }

    @Test("STRING", arguments: strings)
    internal func string(comparator: Comparator, wire: String) throws {
      let filter = try WireQuery.filter("displayName", comparator, .string(.value("Ka")))
      #expect(filter.comparator == wire)
      #expect(filter.fieldValue.value == .string("Ka"))
    }

    @Test("REFERENCE = compares by record name")
    internal func reference() throws {
      let reference = Reference(recordName: "player-mei", action: .deleteSelf)
      let filter = try WireQuery.filter("winner", .equals, .reference(.value(reference)))
      #expect(filter.comparator == "EQUALS")
      guard case .object(let object) = filter.fieldValue.value else {
        Issue.record("expected a reference object, got \(filter.fieldValue.value)")
        return
      }
      #expect(object["recordName"] == .string("player-mei"))
      #expect(object["action"] == nil)
    }

    @Test("LIST contains sends the element")
    internal func listContains() throws {
      let value = FieldValue.reference(.value(Reference(recordName: "player-mei")))
      let filter = try WireQuery.filter("players", .listContains, value)
      #expect(filter.comparator == "LIST_CONTAINS")
      guard case .object(let object) = filter.fieldValue.value else {
        Issue.record("expected a reference object, got \(filter.fieldValue.value)")
        return
      }
      #expect(object["recordName"] == .string("player-mei"))
      let tags = try WireQuery.filter("tags", .notListContains, .string(.value("ranked")))
      #expect(tags.comparator == "NOT_LIST_CONTAINS")
      #expect(tags.fieldValue.value == .string("ranked"))
    }

    @Test("LIST<STRING> member prefixes")
    internal func listMemberBeginsWith() throws {
      let filter = try WireQuery.filter("tags", .listMemberBeginsWith, .string(.value("ra")))
      #expect(filter.comparator == "LIST_MEMBER_BEGINS_WITH")
      let negated = try WireQuery.filter(
        "tags",
        .notListMemberBeginsWith,
        .string(.value("ra"))
      )
      #expect(negated.comparator == "NOT_LIST_MEMBER_BEGINS_WITH")
    }

    @Test("IN sends the list with its element type")
    internal func inList() throws {
      let filter = try WireQuery.filter("handle", .in, .string(.list(["mei", "ka"])))
      #expect(filter.comparator == "IN")
      #expect(filter.fieldValue.value == .array([.string("mei"), .string("ka")]))
      #expect(filter.fieldValue.type == "STRING_LIST")
      let excluded = try WireQuery.filter("rating", .notIn, .int64(.list([1, 2])))
      #expect(excluded.comparator == "NOT_IN")
    }

    @Test("LOCATION near sends NEAR with the distance in meters")
    internal func location() throws {
      let center = Location(latitude: 51.5, longitude: -0.12, altitude: 30)
      let filter = try WireQuery.filter(
        "venue",
        .near(meters: 25_000),
        .location(.value(center))
      )
      #expect(filter.comparator == "NEAR")
      #expect(filter.fieldName == "venue")
      #expect(filter.distance == 25_000)
      guard case .object(let object) = filter.fieldValue.value else {
        Issue.record("expected a location object, got \(filter.fieldValue.value)")
        return
      }
      #expect(object["latitude"] == .number(51.5))
      #expect(object["altitude"] == nil)
    }
  }
}
