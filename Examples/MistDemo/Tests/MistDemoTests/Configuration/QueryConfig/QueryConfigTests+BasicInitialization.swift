//
//  QueryConfigTests+BasicInitialization.swift
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
import MistKit
import Testing

@testable import MistDemoKit

extension QueryConfigTests {
  @Suite("Basic Initialization")
  internal struct BasicInitialization {
    @Test("QueryConfig initializes with default values")
    internal func initializeWithDefaults() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(base: baseConfig)

      #expect(config.zone == "_defaultZone")
      #expect(config.recordType == "Note")
      #expect(config.filters.isEmpty)
      #expect(config.sort == nil)
      #expect(config.limit == 20)
      #expect(config.offset == 0)
      #expect(config.fields == nil)
      #expect(config.continuationMarker == nil)
      #expect(config.output == .json)
    }

    @Test("QueryConfig initializes with custom zone")
    internal func initializeWithCustomZone() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        zone: "customZone"
      )

      #expect(config.zone == "customZone")
      #expect(config.recordType == "Note")
    }

    @Test("QueryConfig initializes with custom record type")
    internal func initializeWithCustomRecordType() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        recordType: "Article"
      )

      #expect(config.zone == "_defaultZone")
      #expect(config.recordType == "Article")
    }
  }
}
