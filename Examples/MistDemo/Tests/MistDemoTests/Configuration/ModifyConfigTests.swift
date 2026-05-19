//
//  ModifyConfigTests.swift
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

internal import Testing

@testable import MistDemoKit

@Suite("ModifyConfig Tests")
internal struct ModifyConfigTests {
  @Test("ModifyConfig initializes with empty operations")
  internal func emptyOperations() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [])

    #expect(config.operations.isEmpty)
    #expect(config.atomic == false)
    #expect(config.output == .json)
  }

  @Test("ModifyConfig defaults atomic to false")
  internal func atomicDefaultsFalse() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [])

    #expect(config.atomic == false)
  }

  @Test("ModifyConfig accepts atomic=true")
  internal func atomicCanBeTrue() async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [], atomic: true)

    #expect(config.atomic == true)
  }

  @Test(
    "ModifyConfig output formats round-trip", arguments: [OutputFormat.json, .table, .csv, .yaml])
  internal func outputFormats(format: OutputFormat) async throws {
    let baseConfig = try await MistDemoConfig()
    let config = ModifyConfig(base: baseConfig, operations: [], output: format)

    #expect(config.output == format)
  }
}
