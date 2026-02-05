//
//  TestFixtures.swift
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

public import Foundation

@testable public import BushelCloudKit
@testable public import BushelFoundation

/// Centralized test data fixtures for all record types
internal enum TestFixtures: Sendable {
  // MARK: - RestoreImage Fixtures

  /// Stable macOS 14.2.1 release (Sonoma)
  internal static let sonoma1421 = RestoreImageRecord(
    version: "14.2.1",
    buildNumber: "23C71",
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),  // Dec 12, 2023
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23C71/RestoreImage.ipsw"),
    fileSize: 13_500_000_000,
    sha256Hash: "abc123def456789abcdef0123456789abcdef0123456789abcdef0123456789ab",
    sha1Hash: "def4567890123456789abcdef01234567890",
    isSigned: true,
    isPrerelease: false,
    source: "ipsw.me",
    notes: "Stable release for macOS Sonoma",
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_702_339_200)
  )

  /// Beta macOS 15.0 (Sequoia)
  internal static let sequoia150Beta = RestoreImageRecord(
    version: "15.0 Beta 3",
    buildNumber: "24A5264n",
    releaseDate: Date(timeIntervalSince1970: 1_720_000_000),  // Jul 3, 2024
    downloadURL: url("https://updates.cdn-apple.com/2024/macos/24A5264n/RestoreImage.ipsw"),
    fileSize: 14_000_000_000,
    sha256Hash: "xyz789uvw012345xyzvuwxyz789012345xyzvuwxyz789012345xyzvuwxyz789",
    sha1Hash: "uvw0123456789abcdef0123456789abcdef01",
    isSigned: false,
    isPrerelease: true,
    source: "mrmacintosh.com",
    notes: "Beta release - unsigned",
    sourceUpdatedAt: nil
  )

  /// Minimal RestoreImage with no optional fields
  internal static let minimalRestoreImage = RestoreImageRecord(
    version: "14.0",
    buildNumber: "23A344",
    releaseDate: Date(timeIntervalSince1970: 1_695_657_600),  // Sep 26, 2023
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23A344/RestoreImage.ipsw"),
    fileSize: 13_000_000_000,
    sha256Hash: "minimal123456789abcdef0123456789abcdef0123456789abcdef0123456789ab",
    sha1Hash: "minimal456789abcdef0123456789abcdef0",
    isSigned: nil,
    isPrerelease: false,
    source: "ipsw.me",
    notes: nil,
    sourceUpdatedAt: nil
  )

  // MARK: - XcodeVersion Fixtures

  /// Xcode 15.1 stable release
  internal static let xcode151 = XcodeVersionRecord(
    version: "15.1",
    buildNumber: "15C65",
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),  // Dec 12, 2023
    downloadURL: URL(
      string: "https://download.developer.apple.com/Developer_Tools/Xcode_15.1/Xcode_15.1.xip"
    ),
    fileSize: 8_000_000_000,
    isPrerelease: false,
    minimumMacOS: "RestoreImage-23C71",
    includedSwiftVersion: "SwiftVersion-5.9.2",
    sdkVersions: #"{"macOS":"14.2","iOS":"17.2","watchOS":"10.2","tvOS":"17.2"}"#,
    notes: "Release notes: https://developer.apple.com/xcode/release-notes/"
  )

  /// Xcode 16.0 beta
  internal static let xcode160Beta = XcodeVersionRecord(
    version: "16.0 Beta 1",
    buildNumber: "16A5171c",
    releaseDate: Date(timeIntervalSince1970: 1_717_977_600),  // Jun 10, 2024
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: true,
    minimumMacOS: "RestoreImage-24A5264n",
    includedSwiftVersion: "SwiftVersion-6.0",
    sdkVersions: nil,
    notes: nil
  )

  /// Minimal Xcode with no optional fields
  internal static let minimalXcode = XcodeVersionRecord(
    version: "15.0",
    buildNumber: "15A240d",
    releaseDate: Date(timeIntervalSince1970: 1_695_657_600),
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: false,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: nil
  )

  // MARK: - SwiftVersion Fixtures

  /// Swift 5.9.2 stable
  internal static let swift592 = SwiftVersionRecord(
    version: "5.9.2",
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),  // Dec 12, 2023
    downloadURL: URL(
      string: "https://download.swift.org/swift-5.9.2-release/xcode/swift-5.9.2-RELEASE-osx.pkg"
    ),
    isPrerelease: false,
    notes: "Stable Swift release bundled with Xcode 15.1"
  )

  /// Swift 6.0 development snapshot
  internal static let swift60Snapshot = SwiftVersionRecord(
    version: "6.0",
    releaseDate: Date(timeIntervalSince1970: 1_717_977_600),  // Jun 10, 2024
    downloadURL: nil,
    isPrerelease: true,
    notes: nil
  )

  /// Minimal Swift version
  internal static let minimalSwift = SwiftVersionRecord(
    version: "5.9",
    releaseDate: Date(timeIntervalSince1970: 1_695_657_600),
    downloadURL: nil,
    isPrerelease: false,
    notes: nil
  )

  // MARK: - DataSourceMetadata Fixtures

  /// IPSW.me metadata - successful fetch
  internal static let metadataIPSWSuccess = DataSourceMetadata(
    sourceName: "ipsw.me",
    recordTypeName: "RestoreImage",
    lastFetchedAt: Date(timeIntervalSince1970: 1_702_339_200),
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_702_300_000),
    recordCount: 42,
    fetchDurationSeconds: 3.5,
    lastError: nil
  )

  /// AppleDB metadata - with error
  internal static let metadataAppleDBError = DataSourceMetadata(
    sourceName: "appledb.dev",
    recordTypeName: "RestoreImage",
    lastFetchedAt: Date(timeIntervalSince1970: 1_702_339_200),
    sourceUpdatedAt: nil,
    recordCount: 0,
    fetchDurationSeconds: 1.2,
    lastError: "HTTP 404: Not Found"
  )

  /// Xcode Releases metadata
  internal static let metadataXcodeReleases = DataSourceMetadata(
    sourceName: "xcodereleases.com",
    recordTypeName: "XcodeVersion",
    lastFetchedAt: Date(timeIntervalSince1970: 1_702_339_200),
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_702_320_000),
    recordCount: 18,
    fetchDurationSeconds: 2.1,
    lastError: nil
  )

  /// Minimal metadata
  internal static let minimalMetadata = DataSourceMetadata(
    sourceName: "swift.org",
    recordTypeName: "SwiftVersion",
    lastFetchedAt: Date(timeIntervalSince1970: 1_702_339_200),
    sourceUpdatedAt: nil,
    recordCount: 0,
    fetchDurationSeconds: 0,
    lastError: nil
  )

  // MARK: - Deduplication Test Fixtures

  // MARK: RestoreImage Merge Scenarios

  /// Same build as sonoma1421, MESU source (authoritative for isSigned)
  internal static let sonoma1421Mesu = RestoreImageRecord(
    version: "14.2.1",
    buildNumber: "23C71",  // Same as sonoma1421
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
    downloadURL: url("https://mesu.apple.com/assets/macos/23C71/RestoreImage.ipsw"),
    fileSize: 0,  // MESU doesn't provide fileSize
    sha256Hash: "",  // MESU doesn't provide hashes
    sha1Hash: "",
    isSigned: false,  // MESU authority: unsigned
    isPrerelease: false,
    source: "mesu.apple.com",
    notes: "MESU signing status",
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_702_400_000)  // Later than sonoma1421
  )

  /// Same build as sonoma1421, AppleDB source with hashes
  internal static let sonoma1421Appledb = RestoreImageRecord(
    version: "14.2.1",
    buildNumber: "23C71",  // Same as sonoma1421
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23C71/RestoreImage.ipsw"),
    fileSize: 13_500_000_000,
    sha256Hash: "different789hash456123different789hash456123different789hash456123diff",
    sha1Hash: "appledb1234567890123456789abcdef0",
    isSigned: true,  // Conflicts with MESU
    isPrerelease: false,
    source: "appledb.dev",
    notes: "AppleDB record",
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_702_350_000)  // Between ipsw.me and MESU
  )

  /// Same build as sonoma1421, incomplete data (missing hashes)
  internal static let sonoma1421Incomplete = RestoreImageRecord(
    version: "14.2.1",
    buildNumber: "23C71",
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23C71/RestoreImage.ipsw"),
    fileSize: 0,  // Missing
    sha256Hash: "",  // Missing
    sha1Hash: "",  // Missing
    isSigned: nil,
    isPrerelease: false,
    source: "test-source",
    notes: nil,
    sourceUpdatedAt: nil
  )

  /// Sequoia 15.1 for sorting tests (newer)
  internal static let sequoia151 = RestoreImageRecord(
    version: "15.1",
    buildNumber: "24B83",
    releaseDate: Date(timeIntervalSince1970: 1_730_000_000),  // Nov 2024
    downloadURL: url("https://updates.cdn-apple.com/2024/macos/24B83/RestoreImage.ipsw"),
    fileSize: 14_500_000_000,
    sha256Hash: "sequoia123456789abcdef0123456789abcdef0123456789abcdef0123456789",
    sha1Hash: "sequoia456789abcdef0123456789abcdef",
    isSigned: true,
    isPrerelease: false,
    source: "ipsw.me",
    notes: "Sequoia 15.1",
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_730_000_000)
  )

  /// Sonoma 14.0 for sorting tests (older)
  internal static let sonoma140 = RestoreImageRecord(
    version: "14.0",
    buildNumber: "23A344",
    releaseDate: Date(timeIntervalSince1970: 1_695_657_600),  // Sep 2023
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23A344/RestoreImage.ipsw"),
    fileSize: 13_000_000_000,
    sha256Hash: "sonoma14hash123456789abcdef0123456789abcdef0123456789abcdef012",
    sha1Hash: "sonoma14hash456789abcdef012345678",
    isSigned: false,
    isPrerelease: false,
    source: "ipsw.me",
    notes: nil,
    sourceUpdatedAt: nil
  )

  /// Record with isSigned=true, old timestamp
  internal static let signedOld = RestoreImageRecord(
    version: "14.3",
    buildNumber: "23D56",
    releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
    downloadURL: url("https://updates.cdn-apple.com/2024/macos/23D56/RestoreImage.ipsw"),
    fileSize: 13_600_000_000,
    sha256Hash: "hash123",
    sha1Hash: "hash456",
    isSigned: true,
    isPrerelease: false,
    source: "ipsw.me",
    notes: nil,
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_705_000_000)  // Older
  )

  /// Record with isSigned=false, newer timestamp (should win)
  internal static let unsignedNewer = RestoreImageRecord(
    version: "14.3",
    buildNumber: "23D56",  // Same build as signedOld
    releaseDate: Date(timeIntervalSince1970: 1_705_000_000),
    downloadURL: url("https://updates.cdn-apple.com/2024/macos/23D56/RestoreImage.ipsw"),
    fileSize: 13_600_000_000,
    sha256Hash: "hash123",
    sha1Hash: "hash456",
    isSigned: false,
    isPrerelease: false,
    source: "appledb.dev",
    notes: nil,
    sourceUpdatedAt: Date(timeIntervalSince1970: 1_706_000_000)  // Newer
  )

  /// RestoreImage for version 14.2 (matches 14.2 and 14.2.x)
  internal static let restoreImage142 = RestoreImageRecord(
    version: "14.2",
    buildNumber: "23C64",
    releaseDate: Date(timeIntervalSince1970: 1_700_000_000),
    downloadURL: url("https://updates.cdn-apple.com/2023/macos/23C64/RestoreImage.ipsw"),
    fileSize: 13_400_000_000,
    sha256Hash: "hash142",
    sha1Hash: "sha142",
    isSigned: true,
    isPrerelease: false,
    source: "ipsw.me",
    notes: nil,
    sourceUpdatedAt: nil
  )

  // MARK: XcodeVersion Reference Resolution Fixtures

  /// Xcode with REQUIRES in notes (to be resolved)
  internal static let xcodeWithRequires142 = XcodeVersionRecord(
    version: "15.1",
    buildNumber: "15C65",
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: false,
    minimumMacOS: nil,  // Will be resolved
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: "REQUIRES:macOS 14.2|NOTES_URL:https://developer.apple.com/notes"
  )

  /// Xcode with REQUIRES using 3-component version
  internal static let xcodeWithRequires1421 = XcodeVersionRecord(
    version: "15.2",
    buildNumber: "15C500b",
    releaseDate: Date(timeIntervalSince1970: 1_710_000_000),
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: true,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: "REQUIRES:macOS 14.2.1|NOTES_URL:https://developer.apple.com/beta"
  )

  /// Xcode with no REQUIRES (should remain nil)
  internal static let xcodeNoRequires = XcodeVersionRecord(
    version: "14.0",
    buildNumber: "14A309",
    releaseDate: Date(timeIntervalSince1970: 1_660_000_000),
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: false,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: nil
  )

  /// Xcode with unparseable REQUIRES
  internal static let xcodeInvalidRequires = XcodeVersionRecord(
    version: "15.0",
    buildNumber: "15A240d",
    releaseDate: Date(timeIntervalSince1970: 1_695_657_600),
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: false,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: "REQUIRES:Something invalid|NOTES_URL:https://example.com"
  )

  // MARK: Xcode/Swift Deduplication Fixtures

  /// Duplicate Xcode build (for deduplication)
  internal static let xcode151Duplicate = XcodeVersionRecord(
    version: "15.1",
    buildNumber: "15C65",  // Same build as xcode151
    releaseDate: Date(timeIntervalSince1970: 1_702_339_200),
    downloadURL: URL(string: "https://different-url.com/Xcode_15.1.xip"),
    fileSize: 8_500_000_000,  // Different metadata
    isPrerelease: false,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: "Duplicate record"
  )

  /// Xcode 16.0 for sorting tests
  internal static let xcode160 = XcodeVersionRecord(
    version: "16.0",
    buildNumber: "16A242d",
    releaseDate: Date(timeIntervalSince1970: 1_725_000_000),  // Sep 2024
    downloadURL: nil,
    fileSize: nil,
    isPrerelease: false,
    minimumMacOS: nil,
    includedSwiftVersion: nil,
    sdkVersions: nil,
    notes: nil
  )

  /// Duplicate Swift version
  internal static let swift592Duplicate = SwiftVersionRecord(
    version: "5.9.2",  // Same as swift592
    releaseDate: Date(timeIntervalSince1970: 1_702_400_000),  // Different date
    downloadURL: URL(string: "https://different-swift-url.com/swift-5.9.2.pkg"),
    isPrerelease: false,
    notes: "Duplicate Swift version"
  )

  /// Swift 6.1 for sorting tests
  internal static let swift61 = SwiftVersionRecord(
    version: "6.1",
    releaseDate: Date(timeIntervalSince1970: 1_730_000_000),  // Nov 2024
    downloadURL: nil,
    isPrerelease: false,
    notes: nil
  )

  // MARK: - VirtualBuddy API Response Fixtures

  /// VirtualBuddy API response for a signed macOS build
  internal static let virtualBuddySignedResponse = """
    {
      "uuid": "67919BEC-F793-4544-A5E6-152EE435DCA6",
      "version": "15.0",
      "build": "24A5327a",
      "code": 0,
      "message": "SUCCESS",
      "isSigned": true
    }
    """

  /// VirtualBuddy API response for an unsigned macOS build
  internal static let virtualBuddyUnsignedResponse = """
    {
      "uuid": "02A12F2F-CE0E-4FBF-8155-884B8D9FD5CB",
      "version": "15.1",
      "build": "24B5024e",
      "code": 94,
      "message": "This device isn't eligible for the requested build.",
      "isSigned": false
    }
    """

  /// VirtualBuddy API response for Sonoma 14.2.1 (signed)
  internal static let virtualBuddySonoma1421Response = """
    {
      "uuid": "A1B2C3D4-E5F6-7890-1234-567890ABCDEF",
      "version": "14.2.1",
      "build": "23C71",
      "code": 0,
      "message": "SUCCESS",
      "isSigned": true
    }
    """

  /// VirtualBuddy API response with build number mismatch
  internal static let virtualBuddyBuildMismatchResponse = """
    {
      "uuid": "MISMATCH-UUID-1234-5678-9ABC-DEF123456789",
      "version": "15.0",
      "build": "WRONG_BUILD",
      "code": 0,
      "message": "SUCCESS",
      "isSigned": true
    }
    """

  // MARK: - Helpers

  /// Create a URL from a string, force unwrapping for test fixtures
  /// Test URLs are known to be valid, so force unwrap is acceptable here
  private static func url(_ string: String) -> URL {
    // swiftlint:disable:next force_unwrapping
    URL(string: string)!
  }
}
// swiftlint:enable identifier_name file_length type_body_length
