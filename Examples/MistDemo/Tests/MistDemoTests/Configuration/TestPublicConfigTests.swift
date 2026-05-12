//
//  TestPublicConfigTests.swift
//  MistDemoTests
//
//  Created by Leo Dion.
//  Copyright © 2026 BrightDigit.
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

@testable import MistDemoKit

@Suite("TestPublicConfig Tests")
internal struct TestPublicConfigTests {
  @Test("Memberwise defaults: recordCount=10, assetSizeKB=100, flags false, lookupEmail nil")
  internal func defaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = TestPublicConfig(base: baseConfig)

    #expect(config.recordCount == 10)
    #expect(config.assetSizeKB == 100)
    #expect(config.skipCleanup == false)
    #expect(config.verbose == false)
    #expect(config.lookupEmail == nil)
  }

  @Test("Memberwise init accepts custom values")
  internal func customValues() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = TestPublicConfig(
      base: baseConfig,
      recordCount: 25,
      assetSizeKB: 512,
      skipCleanup: true,
      verbose: true,
      lookupEmail: "user@example.com"
    )

    #expect(config.recordCount == 25)
    #expect(config.assetSizeKB == 512)
    #expect(config.skipCleanup == true)
    #expect(config.verbose == true)
    #expect(config.lookupEmail == "user@example.com")
  }

  @Test("Memberwise init preserves base configuration values")
  internal func preservesBase() async throws {
    let baseConfig = try await MistDemoConfig(containerIdentifier: "iCloud.integration.test")
    let config = TestPublicConfig(base: baseConfig)

    #expect(config.base.containerIdentifier == "iCloud.integration.test")
  }

  @Test("Memberwise init accepts zero recordCount")
  internal func zeroRecordCount() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = TestPublicConfig(base: baseConfig, recordCount: 0)

    #expect(config.recordCount == 0)
  }
}
