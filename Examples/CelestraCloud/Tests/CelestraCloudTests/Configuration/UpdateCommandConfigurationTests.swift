//
//  UpdateCommandConfigurationTests.swift
//  CelestraCloud
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

@testable import CelestraCloudKit

@Suite("UpdateCommandConfiguration Tests")
internal struct UpdateCommandConfigurationTests {
  @Test("Default values are applied correctly")
  internal func testDefaultValues() {
    let config = UpdateCommandConfiguration()

    #expect(config.delay == 2.0)
    #expect(config.skipRobotsCheck == false)
    #expect(config.maxFailures == nil)
    #expect(config.minPopularity == nil)
    #expect(config.lastAttemptedBefore == nil)
    #expect(config.limit == nil)
  }

  @Test("Custom delay value")
  internal func testCustomDelay() {
    let config = UpdateCommandConfiguration(
      delay: 5.0,
      skipRobotsCheck: false,
      maxFailures: nil,
      minPopularity: nil,
      lastAttemptedBefore: nil,
      limit: nil
    )

    #expect(config.delay == 5.0)
  }

  @Test("Skip robots check flag")
  internal func testSkipRobotsCheck() {
    let config = UpdateCommandConfiguration(
      delay: 2.0,
      skipRobotsCheck: true,
      maxFailures: nil,
      minPopularity: nil,
      lastAttemptedBefore: nil,
      limit: nil
    )

    #expect(config.skipRobotsCheck == true)
  }

  @Test("Max failures value")
  internal func testMaxFailures() {
    let config = UpdateCommandConfiguration(
      delay: 2.0,
      skipRobotsCheck: false,
      maxFailures: 5,
      minPopularity: nil,
      lastAttemptedBefore: nil,
      limit: nil
    )

    #expect(config.maxFailures == 5)
  }

  @Test("Min popularity value")
  internal func testMinPopularity() {
    let config = UpdateCommandConfiguration(
      delay: 2.0,
      skipRobotsCheck: false,
      maxFailures: nil,
      minPopularity: 100,
      lastAttemptedBefore: nil,
      limit: nil
    )

    #expect(config.minPopularity == 100)
  }

  @Test("Last attempted before date")
  internal func testLastAttemptedBefore() {
    let testDate = Date(timeIntervalSince1970: 1_704_067_200) // 2024-01-01T00:00:00Z
    let config = UpdateCommandConfiguration(
      delay: 2.0,
      skipRobotsCheck: false,
      maxFailures: nil,
      minPopularity: nil,
      lastAttemptedBefore: testDate,
      limit: nil
    )

    #expect(config.lastAttemptedBefore == testDate)
  }

  @Test("Limit value")
  internal func testLimit() {
    let config = UpdateCommandConfiguration(
      delay: 2.0,
      skipRobotsCheck: false,
      maxFailures: nil,
      minPopularity: nil,
      lastAttemptedBefore: nil,
      limit: 50
    )

    #expect(config.limit == 50)
  }

  @Test("All custom values")
  internal func testAllCustomValues() {
    let testDate = Date(timeIntervalSince1970: 1_704_067_200)
    let config = UpdateCommandConfiguration(
      delay: 3.5,
      skipRobotsCheck: true,
      maxFailures: 10,
      minPopularity: 200,
      lastAttemptedBefore: testDate,
      limit: 100
    )

    #expect(config.delay == 3.5)
    #expect(config.skipRobotsCheck == true)
    #expect(config.maxFailures == 10)
    #expect(config.minPopularity == 200)
    #expect(config.lastAttemptedBefore == testDate)
    #expect(config.limit == 100)
  }

  @Test("Negative delay value")
  internal func testNegativeDelay() {
    let config = UpdateCommandConfiguration(
      delay: -1.0,
      skipRobotsCheck: false,
      maxFailures: nil,
      minPopularity: nil,
      lastAttemptedBefore: nil,
      limit: nil
    )

    #expect(config.delay == -1.0)
    // Note: Validation should happen at a higher level (command execution)
  }

  @Test("Zero values for numeric fields")
  internal func testZeroValues() {
    let config = UpdateCommandConfiguration(
      delay: 0.0,
      skipRobotsCheck: false,
      maxFailures: 0,
      minPopularity: 0,
      lastAttemptedBefore: nil,
      limit: 0
    )

    #expect(config.delay == 0.0)
    #expect(config.maxFailures == 0)
    #expect(config.minPopularity == 0)
    #expect(config.limit == 0)
  }
}
