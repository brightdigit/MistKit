//
//  DataSourceMetadataTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//

import BushelFoundation
import MistKit
import Testing

@testable import BushelCloudKit

@Suite("DataSourceMetadata CloudKit Mapping")
internal struct DataSourceMetadataTests {
  @Test("Convert successful fetch to CloudKit fields")
  internal func testToCloudKitFieldsSuccess() {
    let record = TestFixtures.metadataIPSWSuccess
    let fields = record.toCloudKitFields()

    fields["sourceName"]?.assertStringEquals("ipsw.me")
    fields["recordTypeName"]?.assertStringEquals("RestoreImage")
    fields["lastFetchedAt"]?.assertIsDate()
    fields["sourceUpdatedAt"]?.assertIsDate()
    fields["recordCount"]?.assertInt64Equals(42)
    fields["fetchDurationSeconds"]?.assertDoubleEquals(3.5)

    #expect(fields["lastError"] == nil)
  }

  @Test("Convert failed fetch to CloudKit fields")
  internal func testToCloudKitFieldsWithError() {
    let record = TestFixtures.metadataAppleDBError
    let fields = record.toCloudKitFields()

    fields["sourceName"]?.assertStringEquals("appledb.dev")
    fields["recordTypeName"]?.assertStringEquals("RestoreImage")
    fields["recordCount"]?.assertInt64Equals(0)
    fields["fetchDurationSeconds"]?.assertDoubleEquals(1.2)
    fields["lastError"]?.assertStringEquals("HTTP 404: Not Found")

    #expect(fields["sourceUpdatedAt"] == nil)
  }

  @Test("Roundtrip conversion preserves data")
  internal func testRoundtripConversion() {
    let original = TestFixtures.metadataIPSWSuccess
    let fields = original.toCloudKitFields()
    let recordInfo = MockRecordInfo.create(
      recordType: "DataSourceMetadata",
      recordName: original.recordName,
      fields: fields
    )

    let reconstructed = DataSourceMetadata.from(recordInfo: recordInfo)

    #expect(reconstructed != nil)
    #expect(reconstructed?.sourceName == original.sourceName)
    #expect(reconstructed?.recordTypeName == original.recordTypeName)
    #expect(reconstructed?.recordCount == original.recordCount)
    #expect(reconstructed?.fetchDurationSeconds == original.fetchDurationSeconds)
    #expect(reconstructed?.lastError == original.lastError)
  }

  @Test("From RecordInfo with missing required fields returns nil")
  internal func testFromRecordInfoMissingFields() {
    let recordInfo = MockRecordInfo.create(
      recordType: "DataSourceMetadata",
      recordName: "test",
      fields: [
        "sourceName": .string("ipsw.me")
        // Missing recordTypeName and lastFetchedAt
      ]
    )

    #expect(DataSourceMetadata.from(recordInfo: recordInfo) == nil)
  }

  @Test("RecordName generation format")
  internal func testRecordNameFormat() {
    #expect(TestFixtures.metadataIPSWSuccess.recordName == "metadata-ipsw.me-RestoreImage")
    #expect(
      TestFixtures.metadataXcodeReleases.recordName == "metadata-xcodereleases.com-XcodeVersion"
    )
  }

  @Test("CloudKit record type is correct")
  internal func testCloudKitRecordType() {
    #expect(DataSourceMetadata.cloudKitRecordType == "DataSourceMetadata")
  }
}
