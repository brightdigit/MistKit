internal import Foundation
internal import Testing

@testable import MistKit

extension QueryDescriptorTests {
  /// Saving and reading back a descriptor keeps every value's type.
  @Suite("Codable")
  internal struct Coding {
    internal typealias Condition = QueryDescriptor.Condition

    internal static let values: [FieldValue] = [
      .string(.value("Ka")),
      .int64(.value(1_500)),
      .double(.value(3)),
      .date(.value(Date(timeIntervalSince1970: 1_790_812_800))),
      .bytes(.value(Data([0, 255]))),
      .reference(.value(Reference(recordName: "p-1"))),
      .location(.value(Location(latitude: 51.5, longitude: -0.12))),
      .string(.list(["a", "b"])),
      .int64(.list([])),
      .date(.list([Date(timeIntervalSince1970: 0)])),
    ]

    @Test("every value type round-trips", arguments: values)
    internal func roundTrip(value: FieldValue) throws {
      let descriptor = QueryDescriptor(
        recordType: "Match",
        zoneID: ZoneID(zoneName: "Tournaments"),
        conditions: [Condition(fieldName: "field", comparator: .equals, value: value)],
        sorts: [QueryDescriptor.Sort(fieldName: "startedAt", ascending: false)],
        desiredKeys: ["score"],
        limit: 20
      )
      let data = try JSONEncoder().encode(descriptor)
      #expect(try JSONDecoder().decode(QueryDescriptor.self, from: data) == descriptor)
    }

    @Test("values are saved with their CloudKit type")
    internal func tagged() throws {
      let condition = Condition(
        fieldName: "startedAt",
        comparator: .near(meters: 25),
        value: .date(.value(Date(timeIntervalSince1970: 1)))
      )
      let data = try JSONEncoder().encode(condition)
      let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
      let value = try #require(object["value"] as? [String: Any])
      #expect(value["type"] as? String == "TIMESTAMP")
      #expect(value["value"] as? Double == 1_000)
      #expect(try JSONDecoder().decode(Condition.self, from: data) == condition)
    }

    @Test("a cleared value doesn't decode")
    internal func clearedValue() {
      let json = Data(
        #"{"fieldName":"a","comparator":{"equals":{}},"value":{"value":null}}"#.utf8
      )
      #expect(throws: DecodingError.self) {
        try JSONDecoder().decode(Condition.self, from: json)
      }
    }

    @Test("every comparator round-trips through its FilterComparator")
    internal func comparators() {
      for comparator in FilterComparator.allCases where comparator != .near {
        #expect(QueryDescriptor.Comparator(comparator)?.filterComparator == comparator)
      }
      #expect(QueryDescriptor.Comparator(.near) == nil)
      #expect(QueryDescriptor.Comparator.near(meters: 5).filterComparator == .near)
      #expect(QueryDescriptor.Comparator.in.takesList)
      #expect(QueryDescriptor.Comparator.notIn.takesList)
      #expect(!QueryDescriptor.Comparator.listContains.takesList)
    }
  }
}
