//
//  RestoreImageMergeTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the "Software"), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

import Foundation
import Testing

@testable import BushelCloudKit
@testable import BushelFoundation

// MARK: - Suite 2: RestoreImage Merge Tests

@Suite("RestoreImage Merge Logic")
internal struct RestoreImageMergeTests {
  internal let pipeline = DataSourcePipeline()

  // MARK: Backfill Tests

  @Test("Backfill SHA256 hash from second record")
  internal func testBackfillSHA256() {
    let incomplete = TestFixtures.sonoma1421Incomplete
    let complete = TestFixtures.sonoma1421

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.sha256Hash == complete.sha256Hash)
    #expect(!merged.sha256Hash.isEmpty)
  }

  @Test("Backfill SHA1 hash from second record")
  internal func testBackfillSHA1() {
    let incomplete = TestFixtures.sonoma1421Incomplete
    let complete = TestFixtures.sonoma1421

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.sha1Hash == complete.sha1Hash)
    #expect(!merged.sha1Hash.isEmpty)
  }

  @Test("Backfill file size from second record")
  internal func testBackfillFileSize() {
    let incomplete = TestFixtures.sonoma1421Incomplete
    let complete = TestFixtures.sonoma1421

    let merged = pipeline.mergeRestoreImages(incomplete, complete)

    #expect(merged.fileSize == complete.fileSize)
    #expect(merged.fileSize > 0)
  }

  // MARK: MESU Authority Tests

  @Test("MESU first takes precedence for isSigned")
  internal func testMESUFirstAuthoritative() {
    let mesu = TestFixtures.sonoma1421Mesu  // isSigned=false
    let ipsw = TestFixtures.sonoma1421  // isSigned=true

    let merged = pipeline.mergeRestoreImages(mesu, ipsw)

    // MESU authority wins
    #expect(merged.isSigned == false)
  }

  @Test("MESU second takes precedence for isSigned")
  internal func testMESUSecondAuthoritative() {
    let ipsw = TestFixtures.sonoma1421  // isSigned=true
    let mesu = TestFixtures.sonoma1421Mesu  // isSigned=false

    let merged = pipeline.mergeRestoreImages(ipsw, mesu)

    // MESU authority wins regardless of order
    #expect(merged.isSigned == false)
  }

  @Test("MESU authority overrides newer timestamp")
  internal func testMESUOverridesNewerTimestamp() {
    let appledb = TestFixtures.sonoma1421Appledb  // newer timestamp, isSigned=true
    let mesu = TestFixtures.sonoma1421Mesu  // MESU, isSigned=false

    let merged = pipeline.mergeRestoreImages(appledb, mesu)

    // MESU authority trumps recency
    #expect(merged.isSigned == false)
  }

  @Test("MESU with nil isSigned does not override")
  internal func testMESUWithNilDoesNotOverride() {
    // Create MESU record with nil isSigned
    let mesuNil = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: URL(string: "https://mesu.apple.com/assets/macos/23C71/RestoreImage.ipsw")!,
      fileSize: 0,
      sha256Hash: "",
      sha1Hash: "",
      isSigned: nil,  // nil value
      isPrerelease: false,
      source: "mesu.apple.com"
    )
    let ipsw = TestFixtures.sonoma1421  // isSigned=true

    let merged = pipeline.mergeRestoreImages(mesuNil, ipsw)

    // nil doesn't override
    #expect(merged.isSigned == true)
  }

  // MARK: Timestamp Comparison Tests

  @Test("Newer sourceUpdatedAt wins when both non-MESU")
  internal func testNewerTimestampWins() {
    let older = TestFixtures.signedOld  // isSigned=true, older timestamp
    let newer = TestFixtures.unsignedNewer  // isSigned=false, newer timestamp

    let merged = pipeline.mergeRestoreImages(older, newer)

    // Newer timestamp wins
    #expect(merged.isSigned == false)
  }

  @Test("Older timestamp loses when both non-MESU")
  internal func testOlderTimestampLoses() {
    let newer = TestFixtures.unsignedNewer  // isSigned=false, newer timestamp
    let older = TestFixtures.signedOld  // isSigned=true, older timestamp

    let merged = pipeline.mergeRestoreImages(newer, older)

    // Newer wins regardless of order
    #expect(merged.isSigned == false)
  }

  @Test("First with timestamp wins when second has no timestamp")
  internal func testFirstTimestampWinsWhenSecondNil() {
    let withTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: Date(timeIntervalSince1970: 1_705_000_000)
    )
    let withoutTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: nil
    )

    let merged = pipeline.mergeRestoreImages(withTimestamp, withoutTimestamp)

    // First with timestamp wins
    #expect(merged.isSigned == true)
  }

  @Test("Second with timestamp wins when first has no timestamp")
  internal func testSecondTimestampWinsWhenFirstNil() {
    let withoutTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: nil
    )
    let withTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: Date(timeIntervalSince1970: 1_706_000_000)
    )

    let merged = pipeline.mergeRestoreImages(withoutTimestamp, withTimestamp)

    // Second with timestamp wins
    #expect(merged.isSigned == false)
  }

  @Test("Equal timestamps prefer first value when set")
  internal func testEqualTimestampsPreferFirst() {
    let sameDate = Date(timeIntervalSince1970: 1_705_000_000)
    let first = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: sameDate
    )
    let second = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: sameDate
    )

    let merged = pipeline.mergeRestoreImages(first, second)

    // First wins when timestamps equal
    #expect(merged.isSigned == true)
  }

  // MARK: Nil Handling Tests

  @Test("Both nil timestamps and values disagree prefers false")
  internal func testBothNilTimestampsPrefersFalse() {
    let signedNilTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: nil,
      sourceUpdatedAt: nil
    )
    let unsignedNilTimestamp = RestoreImageRecord(
      version: "14.3",
      buildNumber: "23D56",
      releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_600_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: false,
      isPrerelease: false,
      source: "appledb.dev",
      notes: nil,
      sourceUpdatedAt: nil
    )

    let merged = pipeline.mergeRestoreImages(signedNilTimestamp, unsignedNilTimestamp)

    // Prefer false when both nil and values disagree
    #expect(merged.isSigned == false)
  }

  @Test("Second isSigned nil preserves first value")
  internal func testSecondNilPreservesFirst() {
    let signed = TestFixtures.sonoma1421  // isSigned=true
    let incomplete = TestFixtures.sonoma1421Incomplete  // isSigned=nil

    let merged = pipeline.mergeRestoreImages(signed, incomplete)

    #expect(merged.isSigned == true)
  }

  @Test("First isSigned nil uses second value")
  internal func testFirstNilUsesSecond() {
    let incomplete = TestFixtures.sonoma1421Incomplete  // isSigned=nil
    let signed = TestFixtures.sonoma1421  // isSigned=true

    let merged = pipeline.mergeRestoreImages(incomplete, signed)

    #expect(merged.isSigned == true)
  }

  // MARK: Notes Combination Test

  @Test("Notes combined with semicolon separator")
  internal func testNotesCombination() {
    let first = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_500_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "ipsw.me",
      notes: "First note"
    )
    let second = RestoreImageRecord(
      version: "14.2.1",
      buildNumber: "23C71",
      releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
      downloadURL: URL(string: "https://example.com/image.ipsw")!,
      fileSize: 13_500_000_000,
      sha256Hash: "hash123",
      sha1Hash: "hash456",
      isSigned: true,
      isPrerelease: false,
      source: "appledb.dev",
      notes: "Second note"
    )

    let merged = pipeline.mergeRestoreImages(first, second)

    #expect(merged.notes == "First note; Second note")
  }
}
