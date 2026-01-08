//
//  RestoreImageDeduplicationTests.swift
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

// MARK: - Suite 1: RestoreImage Deduplication Tests

@Suite("RestoreImage Deduplication")
internal struct RestoreImageDeduplicationTests {
  internal let pipeline = DataSourcePipeline()

  @Test("Empty array returns empty")
  internal func testDeduplicateEmpty() {
    let result = pipeline.deduplicateRestoreImages([])
    #expect(result.isEmpty)
  }

  @Test("Single record returns unchanged")
  internal func testDeduplicateSingle() {
    let input = [TestFixtures.sonoma1421]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 1)
    #expect(result[0].buildNumber == "23C71")
  }

  @Test("Different builds all preserved")
  internal func testDeduplicateDifferentBuilds() {
    let input = [
      TestFixtures.sonoma1421,
      TestFixtures.sequoia151,
      TestFixtures.sonoma140,
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 3)
    // Should be sorted by releaseDate descending
    #expect(result[0].buildNumber == "24B83")  // sequoia151 (Nov 2024)
    #expect(result[1].buildNumber == "23C71")  // sonoma1421 (Dec 2023)
    #expect(result[2].buildNumber == "23A344")  // sonoma140 (Sep 2023)
  }

  @Test("Duplicate builds merged")
  internal func testDeduplicateDuplicateBuilds() {
    let input = [
      TestFixtures.sonoma1421,
      TestFixtures.sonoma1421Mesu,
      TestFixtures.sonoma1421Appledb,
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    // Should have only 1 record after merging
    #expect(result.count == 1)
    #expect(result[0].buildNumber == "23C71")
  }

  @Test("Results sorted by release date descending")
  internal func testSortingByReleaseDateDescending() {
    let input = [
      TestFixtures.sonoma140,  // Oldest: Sep 2023
      TestFixtures.sonoma1421,  // Middle: Dec 2023
      TestFixtures.sequoia151,  // Newest: Nov 2024
    ]
    let result = pipeline.deduplicateRestoreImages(input)

    #expect(result.count == 3)
    // Verify descending order
    #expect(result[0].releaseDate > result[1].releaseDate)
    #expect(result[1].releaseDate > result[2].releaseDate)
  }
}
