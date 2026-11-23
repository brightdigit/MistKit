internal import Foundation
internal import Testing

@testable import MistKit

@Suite("Record Identity")
/// `Identifiable`, `Hashable` and `CaseIterable` on records, zones and
/// environments (brightdigit/MistKit#501).
internal struct RecordIdentityTests {
  @Test("RecordInfo is identified by its record name")
  internal func recordInfoID() {
    let record = RecordInfo(
      recordName: "note-1",
      recordType: "Note",
      fields: ["title": .string(.value("A"))]
    )
    #expect(record.id == "note-1")
  }

  @Test("Equal RecordInfo values hash alike; a changed field does not compare equal")
  internal func recordInfoHashable() {
    let stamp = RecordTimestamp(timestamp: Date(timeIntervalSince1970: 10), userRecordName: "u")
    let lhs = RecordInfo(
      recordName: "a",
      zoneID: ZoneID(zoneName: "Z"),
      recordType: "T",
      fields: ["n": .double(.list([0.0, 1]))],
      created: stamp
    )
    let rhs = RecordInfo(
      recordName: "a",
      zoneID: ZoneID(zoneName: "Z"),
      recordType: "T",
      fields: ["n": .double(.list([-0.0, 1]))],
      created: stamp
    )
    let changed = RecordInfo(
      recordName: "a",
      zoneID: ZoneID(zoneName: "Z"),
      recordType: "T",
      fields: ["n": .double(.list([2, 1]))],
      created: stamp
    )
    #expect(lhs == rhs)
    #expect(lhs.hashValue == rhs.hashValue)
    #expect(lhs != changed)
    #expect(Set([lhs, rhs, changed]).count == 2)
  }

  @Test("RecordTimestamp hashes consistently with ==")
  internal func recordTimestampHashable() {
    let lhs = RecordTimestamp(timestamp: nil, userRecordName: "u")
    let rhs = RecordTimestamp(userRecordName: "u")
    #expect(lhs == rhs)
    #expect(Set([lhs, rhs, RecordTimestamp()]).count == 2)
  }

  @Test("ZoneInfo is identified by its name and owner, not its type")
  internal func zoneInfoID() {
    let zone = ZoneInfo(
      zoneName: "Articles",
      ownerRecordName: "_owner",
      capabilities: [],
      zoneType: .regularCustom,
      atomic: true
    )
    #expect(zone.id == ZoneID(zoneName: "Articles", ownerName: "_owner"))
    #expect(zone.id.zoneType == nil)
  }

  @Test("ZoneInfo hashes consistently with ==")
  internal func zoneInfoHashable() {
    let lhs = ZoneInfo(zoneName: "Z", ownerRecordName: nil, capabilities: [], atomic: true)
    let rhs = ZoneInfo(zoneName: "Z", ownerRecordName: nil, capabilities: [], atomic: true)
    let other = ZoneInfo(zoneName: "Z", ownerRecordName: nil, capabilities: [], atomic: nil)
    #expect(lhs == rhs)
    #expect(lhs.hashValue == rhs.hashValue)
    #expect(Set([lhs, rhs, other]).count == 2)
  }

  @Test("Environment lists every case")
  internal func environmentAllCases() {
    #expect(Environment.allCases == [.development, .production])
  }
}
