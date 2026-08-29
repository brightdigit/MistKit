//
//  FetchZoneRecordChangesConfigTests.swift
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

internal import Foundation
internal import Testing

@testable import MistDemoKit

@Suite("FetchZoneRecordChangesConfig Tests")
internal struct FetchZoneRecordChangesConfigTests {
  @Test("FetchZoneRecordChangesConfig defaults zones to _defaultZone, fetchAll false, output table")
  internal func defaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(base: baseConfig)

    #expect(config.zones == ["_defaultZone"])
    #expect(config.syncToken == nil)
    #expect(config.fetchAll == false)
    #expect(config.limit == nil)
    #expect(config.output == .table)
  }

  @Test("FetchZoneRecordChangesConfig accepts multiple zones preserving order")
  internal func multipleZones() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(
      base: baseConfig,
      zones: ["Articles", "Photos"]
    )

    #expect(config.zones == ["Articles", "Photos"])
  }

  @Test("FetchZoneRecordChangesConfig accepts custom syncToken and limit")
  internal func customValues() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(
      base: baseConfig,
      syncToken: "tok-1",
      fetchAll: true,
      limit: 50
    )

    #expect(config.syncToken == "tok-1")
    #expect(config.fetchAll == true)
    #expect(config.limit == 50)
  }

  @Test(
    "FetchZoneRecordChangesConfig output formats round-trip",
    arguments: [OutputFormat.json, .table, .csv, .yaml]
  )
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(base: baseConfig, output: format)

    #expect(config.output == format)
  }

  @Test("FetchZoneRecordChangesConfig defaults desiredKeys and desiredRecordTypes to nil")
  internal func changeFeedOptionsDefaultToNil() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(base: baseConfig)

    #expect(config.desiredKeys == nil)
    #expect(config.desiredRecordTypes == nil)
  }

  @Test("FetchZoneRecordChangesConfig carries explicit desiredKeys and desiredRecordTypes")
  internal func carriesChangeFeedOptions() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchZoneRecordChangesConfig(
      base: baseConfig,
      desiredKeys: ["title", "body"],
      desiredRecordTypes: ["Note", "Comment"]
    )

    #expect(config.desiredKeys == ["title", "body"])
    #expect(config.desiredRecordTypes == ["Note", "Comment"])
  }
}
