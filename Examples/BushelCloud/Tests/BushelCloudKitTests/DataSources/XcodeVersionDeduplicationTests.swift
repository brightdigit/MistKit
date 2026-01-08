//
//  XcodeVersionDeduplicationTests.swift
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

// MARK: - Suite 4: XcodeVersion Deduplication Tests

@Suite("XcodeVersion Deduplication")
internal struct XcodeVersionDeduplicationTests {
  internal let pipeline = DataSourcePipeline()

  @Test("Empty array returns empty")
  internal func testDeduplicateEmpty() {
    let result = pipeline.deduplicateXcodeVersions([])
    #expect(result.isEmpty)
  }

  @Test("Single record returns unchanged")
  internal func testDeduplicateSingle() {
    let input = [TestFixtures.xcode151]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 1)
    #expect(result[0].buildNumber == "15C65")
  }

  @Test("Duplicate builds keep first occurrence")
  internal func testDuplicateBuildsKeepFirst() {
    let input = [
      TestFixtures.xcode151,
      TestFixtures.xcode151Duplicate,
    ]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 1)
    // Should keep first occurrence
    #expect(result[0].buildNumber == "15C65")
    #expect(result[0].notes == "Release notes: https://developer.apple.com/xcode/release-notes/")
  }

  @Test("Results sorted by release date descending")
  internal func testSortingByReleaseDateDescending() {
    let input = [
      TestFixtures.xcode151,  // Dec 2023
      TestFixtures.xcode160,  // Sep 2024
    ]
    let result = pipeline.deduplicateXcodeVersions(input)

    #expect(result.count == 2)
    // Verify descending order (newer first)
    #expect(result[0].buildNumber == "16A242d")  // xcode160
    #expect(result[1].buildNumber == "15C65")  // xcode151
  }
}
