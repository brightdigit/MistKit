//
//  SwiftVersionRecordTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//

import MistKit
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

@Suite("SwiftVersionRecord CloudKit Mapping")
internal struct SwiftVersionRecordTests {
  @Test("Convert to CloudKit fields with all data")
  internal func testToCloudKitFieldsComplete() {
    let record = TestFixtures.swift592
    let fields = record.toCloudKitFields()

    fields["version"]?.assertStringEquals("5.9.2")
    fields["releaseDate"]?.assertIsDate()
    fields["isPrerelease"]?.assertBoolEquals(false)
    fields["downloadURL"]?.assertStringEquals(
      "https://download.swift.org/swift-5.9.2-release/xcode/swift-5.9.2-RELEASE-osx.pkg"
    )
    fields["notes"]?.assertStringEquals("Stable Swift release bundled with Xcode 15.1")
  }

  @Test("Convert snapshot record to CloudKit fields")
  internal func testToCloudKitFieldsSnapshot() {
    let record = TestFixtures.swift60Snapshot
    let fields = record.toCloudKitFields()

    fields["version"]?.assertStringEquals("6.0")
    fields["isPrerelease"]?.assertBoolEquals(true)

    #expect(fields["downloadURL"] == nil)
    #expect(fields["notes"] == nil)
  }

  @Test("Roundtrip conversion preserves data")
  internal func testRoundtripConversion() {
    let original = TestFixtures.swift592
    let fields = original.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "SwiftVersion",
      recordName: original.recordName,
      fields: fields
    )

    let reconstructed = SwiftVersionRecord.from(recordInfo: recordInfo)

    #expect(reconstructed != nil)
    #expect(reconstructed?.version == original.version)
    #expect(reconstructed?.isPrerelease == original.isPrerelease)
    #expect(reconstructed?.downloadURL == original.downloadURL)
    #expect(reconstructed?.notes == original.notes)
  }

  @Test("From RecordInfo with missing required fields returns nil")
  internal func testFromRecordInfoMissingFields() {
    let recordInfo = MockRecordInfo.create(
      recordType: "SwiftVersion",
      recordName: "test",
      fields: [
        "version": .string("5.9.2")
        // Missing releaseDate
      ]
    )

    #expect(SwiftVersionRecord.from(recordInfo: recordInfo) == nil)
  }

  @Test("RecordName generation format")
  internal func testRecordNameFormat() {
    #expect(TestFixtures.swift592.recordName == "SwiftVersion-5.9.2")
    #expect(TestFixtures.swift60Snapshot.recordName == "SwiftVersion-6.0")
  }

  @Test("CloudKit record type is correct")
  internal func testCloudKitRecordType() {
    #expect(SwiftVersionRecord.cloudKitRecordType == "SwiftVersion")
  }
}
