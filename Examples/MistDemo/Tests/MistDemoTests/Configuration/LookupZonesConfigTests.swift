//
//  LookupZonesConfigTests.swift
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

@Suite("LookupZonesConfig Tests")
internal struct LookupZonesConfigTests {
  @Test("LookupZonesConfig initializes with a single zone name")
  internal func singleZoneName() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupZonesConfig(base: baseConfig, zoneNames: ["_defaultZone"])

    #expect(config.zoneNames == ["_defaultZone"])
    #expect(config.output == .table)
  }

  @Test("LookupZonesConfig initializes with multiple zone names preserving order")
  internal func multipleZoneNames() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupZonesConfig(base: baseConfig, zoneNames: ["zone-z", "zone-a", "zone-m"])

    #expect(config.zoneNames == ["zone-z", "zone-a", "zone-m"])
  }

  @Test(
    "LookupZonesConfig output formats round-trip",
    arguments: [OutputFormat.json, .table, .csv, .yaml]
  )
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = LookupZonesConfig(
      base: baseConfig,
      zoneNames: ["_defaultZone"],
      output: format
    )

    #expect(config.output == format)
  }
}
