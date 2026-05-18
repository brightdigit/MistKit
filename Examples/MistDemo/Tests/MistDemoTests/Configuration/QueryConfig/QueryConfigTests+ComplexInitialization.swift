//
//  QueryConfigTests+ComplexInitialization.swift
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

extension QueryConfigTests {
  @Suite("Complex Initialization")
  internal struct ComplexInitialization {
    @Test("QueryConfig initializes with all custom values")
    internal func initializeWithAllCustomValues() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        zone: "customZone",
        recordType: "Article",
        filters: ["status=published", "category=tech"],
        sort: (field: "publishedAt", order: .descending),
        limit: 50,
        offset: 20,
        fields: ["title", "content", "author"],
        continuationMarker: "marker-xyz789",
        output: .yaml
      )

      #expect(config.zone == "customZone")
      #expect(config.recordType == "Article")
      #expect(config.filters.count == 2)
      #expect(config.sort?.field == "publishedAt")
      #expect(config.sort?.order == .descending)
      #expect(config.limit == 50)
      #expect(config.offset == 20)
      #expect(config.fields?.count == 3)
      #expect(config.continuationMarker == "marker-xyz789")
      #expect(config.output == .yaml)
    }

    @Test("QueryConfig handles pagination scenario")
    internal func handlePaginationScenario() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        limit: 10,
        offset: 30,
        continuationMarker: "page-4"
      )

      #expect(config.limit == 10)
      #expect(config.offset == 30)
      #expect(config.continuationMarker == "page-4")
    }
  }
}
