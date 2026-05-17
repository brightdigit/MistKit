//
//  DeleteConfigTests.swift
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

@Suite("DeleteConfig Tests")
internal struct DeleteConfigTests {
  @Test("DeleteConfig initializes with defaults")
  internal func initializeWithDefaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-1")

    #expect(config.recordName == "rec-1")
    #expect(config.zone == "_defaultZone")
    #expect(config.recordType == "Note")
    #expect(config.recordChangeTag == nil)
    #expect(config.force == false)
    #expect(config.output == .json)
  }

  @Test("DeleteConfig initializes with custom zone and record type")
  internal func initializeWithCustomZoneAndType() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(
      base: baseConfig,
      zone: "myZone",
      recordType: "Article",
      recordName: "rec-1"
    )

    #expect(config.zone == "myZone")
    #expect(config.recordType == "Article")
  }

  @Test("DeleteConfig accepts a record change tag")
  internal func recordChangeTag() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(
      base: baseConfig,
      recordName: "rec-1",
      recordChangeTag: "tag-xyz"
    )

    #expect(config.recordChangeTag == "tag-xyz")
  }

  @Test("DeleteConfig defaults force to false")
  internal func forceDefaultsFalse() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-1")

    #expect(config.force == false)
  }

  @Test("DeleteConfig accepts force=true")
  internal func forceCanBeTrue() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-1", force: true)

    #expect(config.force == true)
  }

  @Test(
    "DeleteConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-1", output: format)

    #expect(config.output == format)
  }

  @Test("DeleteConfig handles all custom values together")
  internal func allCustomValues() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(
      base: baseConfig,
      zone: "Z",
      recordType: "T",
      recordName: "R",
      recordChangeTag: "tag",
      force: true,
      output: .yaml
    )

    #expect(config.zone == "Z")
    #expect(config.recordType == "T")
    #expect(config.recordName == "R")
    #expect(config.recordChangeTag == "tag")
    #expect(config.force == true)
    #expect(config.output == .yaml)
  }

  @Test("DeleteConfig preserves special characters in record name")
  internal func specialCharactersInRecordName() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = DeleteConfig(base: baseConfig, recordName: "rec-name_with.special@chars")

    #expect(config.recordName == "rec-name_with.special@chars")
  }
}
