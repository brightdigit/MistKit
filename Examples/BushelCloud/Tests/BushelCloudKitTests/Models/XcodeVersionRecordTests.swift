//
//  XcodeVersionRecordTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//

import MistKit
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

@Suite("XcodeVersionRecord CloudKit Mapping")
internal struct XcodeVersionRecordTests {
  @Test("Convert to CloudKit fields with all data")
  internal func testToCloudKitFieldsComplete() {
    let record = TestFixtures.xcode151
    let fields = record.toCloudKitFields()

    fields["version"]?.assertStringEquals("15.1")
    fields["buildNumber"]?.assertStringEquals("15C65")
    fields["isPrerelease"]?.assertBoolEquals(false)
    fields["downloadURL"]?.assertStringEquals(
      "https://download.developer.apple.com/Developer_Tools/Xcode_15.1/Xcode_15.1.xip"
    )
    fields["fileSize"]?.assertInt64Equals(8_000_000_000)
    fields["releaseDate"]?.assertIsDate()

    // References
    fields["minimumMacOS"]?.assertReferenceEquals("RestoreImage-23C71")
    fields["includedSwiftVersion"]?.assertReferenceEquals("SwiftVersion-5.9.2")

    // Optional fields
    fields["sdkVersions"]?.assertStringEquals(
      #"{"macOS":"14.2","iOS":"17.2","watchOS":"10.2","tvOS":"17.2"}"#
    )
    fields["notes"]?.assertStringEquals(
      "Release notes: https://developer.apple.com/xcode/release-notes/"
    )
  }

  @Test("Convert beta record to CloudKit fields")
  internal func testToCloudKitFieldsBeta() {
    let record = TestFixtures.xcode160Beta
    let fields = record.toCloudKitFields()

    fields["version"]?.assertStringEquals("16.0 Beta 1")
    fields["buildNumber"]?.assertStringEquals("16A5171c")
    fields["isPrerelease"]?.assertBoolEquals(true)

    // Beta has nil optional fields
    #expect(fields["downloadURL"] == nil)
    #expect(fields["fileSize"] == nil)
    #expect(fields["sdkVersions"] == nil)
    #expect(fields["notes"] == nil)
  }

  @Test("Roundtrip conversion preserves data")
  internal func testRoundtripConversion() {
    let original = TestFixtures.xcode151
    let fields = original.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "XcodeVersion",
      recordName: original.recordName,
      fields: fields
    )

    let reconstructed = XcodeVersionRecord.from(recordInfo: recordInfo)

    #expect(reconstructed != nil)
    #expect(reconstructed?.version == original.version)
    #expect(reconstructed?.buildNumber == original.buildNumber)
    #expect(reconstructed?.isPrerelease == original.isPrerelease)
    #expect(reconstructed?.downloadURL == original.downloadURL)
    #expect(reconstructed?.fileSize == original.fileSize)
    #expect(reconstructed?.minimumMacOS == original.minimumMacOS)
    #expect(reconstructed?.includedSwiftVersion == original.includedSwiftVersion)
    #expect(reconstructed?.sdkVersions == original.sdkVersions)
    #expect(reconstructed?.notes == original.notes)
  }

  @Test("From RecordInfo with missing required fields returns nil")
  internal func testFromRecordInfoMissingFields() {
    let recordInfo = MockRecordInfo.create(
      recordType: "XcodeVersion",
      recordName: "test",
      fields: [
        "version": .string("15.1")
        // Missing buildNumber and releaseDate
      ]
    )

    #expect(XcodeVersionRecord.from(recordInfo: recordInfo) == nil)
  }

  @Test("RecordName generation format")
  internal func testRecordNameFormat() {
    #expect(TestFixtures.xcode151.recordName == "XcodeVersion-15C65")
    #expect(TestFixtures.xcode160Beta.recordName == "XcodeVersion-16A5171c")
  }

  @Test("CloudKit record type is correct")
  internal func testCloudKitRecordType() {
    #expect(XcodeVersionRecord.cloudKitRecordType == "XcodeVersion")
  }

  @Test("Reference fields are optional")
  internal func testOptionalReferences() {
    let record = TestFixtures.minimalXcode
    let fields = record.toCloudKitFields()

    #expect(fields["minimumMacOS"] == nil)
    #expect(fields["includedSwiftVersion"] == nil)
  }
}
