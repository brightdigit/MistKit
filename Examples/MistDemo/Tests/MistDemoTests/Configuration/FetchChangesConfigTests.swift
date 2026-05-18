//
//  FetchChangesConfigTests.swift
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

@Suite("FetchChangesConfig Tests")
internal struct FetchChangesConfigTests {
  @Test("FetchChangesConfig defaults zone to _defaultZone, fetchAll false, output table")
  internal func defaults() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchChangesConfig(base: baseConfig)

    #expect(config.syncToken == nil)
    #expect(config.zone == "_defaultZone")
    #expect(config.fetchAll == false)
    #expect(config.limit == nil)
    #expect(config.output == .table)
  }

  @Test("FetchChangesConfig accepts custom zone, syncToken and limit")
  internal func customValues() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchChangesConfig(
      base: baseConfig,
      syncToken: "tok-1",
      zone: "myZone",
      fetchAll: true,
      limit: 50
    )

    #expect(config.syncToken == "tok-1")
    #expect(config.zone == "myZone")
    #expect(config.fetchAll == true)
    #expect(config.limit == 50)
  }

  @Test(
    "FetchChangesConfig output formats round-trip",
    arguments: [OutputFormat.json, .table, .csv, .yaml]
  )
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchChangesConfig(base: baseConfig, output: format)

    #expect(config.output == format)
  }

  @Test("FetchChangesConfig fetchAll true with no syncToken parses as initial fetch")
  internal func initialFetchSemantics() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchChangesConfig(base: baseConfig, fetchAll: true)

    #expect(config.fetchAll == true)
    #expect(config.syncToken == nil)
  }

  @Test("FetchChangesConfig limit nil means fetch with default page size")
  internal func nilLimit() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = FetchChangesConfig(base: baseConfig, limit: nil)

    #expect(config.limit == nil)
  }
}
