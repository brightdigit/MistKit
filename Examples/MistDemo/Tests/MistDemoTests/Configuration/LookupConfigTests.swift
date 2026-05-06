//
//  LookupConfigTests.swift
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

@Suite("LookupConfig Tests")
internal struct LookupConfigTests {
  @Test("LookupConfig initializes with a single record name")
  internal func singleRecordName() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(base: baseConfig, recordNames: ["rec-1"])

    #expect(config.recordNames == ["rec-1"])
    #expect(config.fields == nil)
    #expect(config.output == .json)
  }

  @Test("LookupConfig initializes with multiple record names")
  internal func multipleRecordNames() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(base: baseConfig, recordNames: ["a", "b", "c"])

    #expect(config.recordNames == ["a", "b", "c"])
  }

  @Test("LookupConfig initializes with explicit fields filter")
  internal func explicitFields() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(
      base: baseConfig,
      recordNames: ["rec-1"],
      fields: ["title", "priority"]
    )

    #expect(config.fields == ["title", "priority"])
  }

  @Test("LookupConfig fields is nil when not provided")
  internal func fieldsDefaultNil() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(base: baseConfig, recordNames: ["rec-1"])

    #expect(config.fields == nil)
  }

  @Test(
    "LookupConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(base: baseConfig, recordNames: ["rec-1"], output: format)

    #expect(config.output == format)
  }

  @Test("LookupConfig preserves order of record names")
  internal func preservesOrder() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupConfig(base: baseConfig, recordNames: ["z", "a", "m"])

    #expect(config.recordNames == ["z", "a", "m"])
  }

  @Test("LookupConfig handles many record names")
  internal func manyRecordNames() async throws {
    let baseConfig = try await MistDemoConfig()
    let names = (0..<50).map { "rec-\($0)" }
    let config = LookupConfig(base: baseConfig, recordNames: names)

    #expect(config.recordNames.count == 50)
    #expect(config.recordNames.first == "rec-0")
    #expect(config.recordNames.last == "rec-49")
  }
}
