//
//  XcodeVersionReferenceResolutionTests.swift
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

// MARK: - Suite 3: XcodeVersion Reference Resolution Tests

@Suite("XcodeVersion Reference Resolution")
internal struct XcodeVersionReferenceResolutionTests {
  internal let pipeline = DataSourcePipeline()

  @Test("Resolve exact version match 14.2")
  internal func testResolveExactMatch() {
    let xcode = TestFixtures.xcodeWithRequires142
    let restoreImages = [TestFixtures.restoreImage142]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C64")
  }

  @Test("Resolve 3-component version 14.2.1")
  internal func testResolveThreeComponentVersion() {
    let xcode = TestFixtures.xcodeWithRequires1421
    let restoreImages = [TestFixtures.sonoma1421]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
  }

  @Test("Resolve 2-component to 3-component match")
  internal func testResolveTwoToThreeComponent() {
    let xcode = TestFixtures.xcodeWithRequires142
    let restoreImages = [TestFixtures.sonoma1421]  // version="14.2.1"

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    // Should match via short version "14.2" to "14.2.1"
    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
  }

  @Test("No match leaves minimumMacOS nil")
  internal func testNoMatchLeavesNil() {
    let xcode = TestFixtures.xcodeWithRequires142
    let restoreImages = [TestFixtures.sequoia151]  // Different version

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("No REQUIRES field leaves minimumMacOS nil")
  internal func testNoRequiresLeavesNil() {
    let xcode = TestFixtures.xcodeNoRequires
    let restoreImages = [TestFixtures.sonoma1421]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("Invalid REQUIRES format leaves minimumMacOS nil")
  internal func testInvalidRequiresLeavesNil() {
    let xcode = TestFixtures.xcodeInvalidRequires
    let restoreImages = [TestFixtures.sonoma1421]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("NOTES_URL preserved after resolution")
  internal func testNotesURLPreserved() {
    let xcode = TestFixtures.xcodeWithRequires142
    let restoreImages = [TestFixtures.restoreImage142]

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].notes == "https://developer.apple.com/notes")
  }

  @Test("Empty restoreImages array leaves all nil")
  internal func testEmptyRestoreImagesArray() {
    let xcode = TestFixtures.xcodeWithRequires142
    let restoreImages: [RestoreImageRecord] = []

    let resolved = pipeline.resolveXcodeVersionReferences([xcode], restoreImages: restoreImages)

    #expect(resolved.count == 1)
    #expect(resolved[0].minimumMacOS == nil)
  }

  @Test("Multiple Xcodes resolved correctly")
  internal func testMultipleXcodeResolution() {
    let xcodes = [
      TestFixtures.xcodeWithRequires142,
      TestFixtures.xcodeWithRequires1421,
      TestFixtures.xcodeNoRequires,
    ]
    let restoreImages = [
      TestFixtures.restoreImage142,
      TestFixtures.sonoma1421,
    ]

    let resolved = pipeline.resolveXcodeVersionReferences(xcodes, restoreImages: restoreImages)

    #expect(resolved.count == 3)
    // When both "14.2" and "14.2.1" exist, the short version from "14.2.1"
    // overwrites "14.2" in the lookup table (last processed wins)
    // First should resolve to 14.2.1 (due to lookup table collision)
    #expect(resolved[0].minimumMacOS == "RestoreImage-23C71")
    // Second should resolve to 14.2.1 (exact match)
    #expect(resolved[1].minimumMacOS == "RestoreImage-23C71")
    // Third has no REQUIRES, should remain nil
    #expect(resolved[2].minimumMacOS == nil)
  }
}
