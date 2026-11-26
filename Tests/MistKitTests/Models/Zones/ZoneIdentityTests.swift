internal import Foundation
internal import MistKit
internal import Testing

@Suite("Zone identity")
/// Tests `ZoneID` identity helpers, `ZoneInfo+Atomic` and `Reference+NormalizedZone`.
internal struct ZoneIdentityTests {
  private let reported = ZoneID(zoneName: "Notes", ownerName: "_owner", zoneType: .regularCustom)

  @Test("the default zone is recognised by name, whatever its owner")
  internal func defaultZoneByName() {
    #expect(ZoneID.defaultZone.isDefaultZone)
    #expect(ZoneID(zoneName: "_defaultZone", ownerName: "_owner").isDefaultZone)
    #expect(!reported.isDefaultZone)
  }

  @Test("identity drops the zone type; normalized maps the default zone")
  internal func identity() {
    #expect(reported.identity == ZoneID(zoneName: "Notes", ownerName: "_owner"))
    #expect(reported != reported.identity)
    let ownedDefault = ZoneID(zoneName: "_defaultZone", ownerName: "_owner", zoneType: .defaultZone)
    #expect(ownedDefault.normalized == .defaultZone)
    #expect(reported.normalized == reported.identity)
  }

  @Test("a request names no zone for the default zone")
  internal func requestZone() {
    #expect(ZoneID(zoneName: "_defaultZone", ownerName: "_owner").requestZone == nil)
    #expect(reported.requestZone == reported)
  }

  @Test("a zone with no atomic flag isn't atomic")
  internal func atomic() {
    let zone = ZoneInfo(id: ZoneID(zoneName: "Notes"), isAtomic: true)
    #expect(zone.isAtomic)
    #expect(zone.id == ZoneID(zoneName: "Notes"))
    #expect(!ZoneInfo(zoneName: "Notes", ownerRecordName: nil, capabilities: []).isAtomic)
  }

  @Test("references normalize their zone; other values are unchanged")
  internal func references() {
    let toDefault = Reference(
      recordName: "a",
      zoneID: ZoneID(zoneName: "_defaultZone", ownerName: "_owner", zoneType: .defaultZone)
    )
    #expect(toDefault.normalizedZone.zoneID == nil)
    let toNotes = Reference(recordName: "b", zoneID: reported, action: .deleteSelf)
    #expect(
      toNotes.normalizedZone
        == Reference(
          recordName: "b", zoneID: reported.identity, action: .deleteSelf
        ))
    let list = FieldValue.reference(.list([toDefault, toNotes]))
    #expect(
      list.withNormalizedReferences
        == .reference(.list([toDefault.normalizedZone, toNotes.normalizedZone]))
    )
    #expect(FieldValue.string(.value("x")).withNormalizedReferences == .string(.value("x")))
  }
}
