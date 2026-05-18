//
//  CommandIntegrationTests+QueryCommandIntegration.swift
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

extension CommandIntegrationTests {
  @Suite("QueryCommand Integration")
  internal struct QueryCommandIntegration {
    private static func createTestConfig() async throws -> MistDemoConfig {
      try await MistDemoConfig()
    }

    @Test("QueryCommand with filters and sorting")
    internal func queryCommandWithFiltersAndSorting() async throws {
      let baseConfig = try await Self.createTestConfig()
      let config = QueryConfig(
        base: baseConfig,
        zone: "_defaultZone",
        recordType: "Note",
        filters: ["title:contains:Test", "priority:gt:3"],
        sort: (field: "createdAt", order: .descending),
        limit: 50,
        fields: ["title", "content", "createdAt"]
      )

      _ = QueryCommand(config: config)

      // Verify query configuration
      #expect(QueryCommand.commandName == "query")
      #expect(config.filters.count == 2)
      #expect(config.sort?.field == "createdAt")
      #expect(config.sort?.order == .descending)
      #expect(config.limit == 50)
    }

    @Test("QueryCommand pagination setup")
    internal func queryCommandPaginationSetup() async throws {
      let baseConfig = try await Self.createTestConfig()
      let config = QueryConfig(
        base: baseConfig,
        limit: 10,
        offset: 20,
        continuationMarker: "next-page-token"
      )

      _ = QueryCommand(config: config)

      // Verify pagination configuration
      #expect(config.limit == 10)
      #expect(config.offset == 20)
      #expect(config.continuationMarker == "next-page-token")
    }
  }
}
