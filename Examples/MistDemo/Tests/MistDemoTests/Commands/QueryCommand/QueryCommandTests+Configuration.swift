//
//  QueryCommandTests+Configuration.swift
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
internal import MistKit
internal import Testing

@testable import MistDemoKit

extension QueryCommandTests {
  @Suite("Configuration")
  internal struct Configuration {
    @Test("QueryConfig initializes with default values")
    internal func queryConfigInitializesWithDefaults() async throws {
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

    @Test("QueryConfig accepts custom values")
    internal func queryConfigAcceptsCustomValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        zone: "customZone",
        recordType: "CustomType",
        filters: ["title:eq:Test"],
        sort: (field: "createdAt", order: .descending),
        limit: 50,
        offset: 10,
        fields: ["title", "content"],
        continuationMarker: "marker123",
        output: .table
      )

      #expect(config.zone == "customZone")
      #expect(config.recordType == "CustomType")
      #expect(config.filters == ["title:eq:Test"])
      #expect(config.sort?.field == "createdAt")
      #expect(config.sort?.order == .descending)
      #expect(config.limit == 50)
      #expect(config.offset == 10)
      #expect(config.fields == ["title", "content"])
      #expect(config.continuationMarker == "marker123")
      #expect(config.output == .table)
    }
  }
}
