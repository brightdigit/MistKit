//
//  QueryConfigTests+SortOption.swift
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
  @Suite("Sort Option")
  internal struct SortOption {
    @Test("QueryConfig initializes with nil sort")
    internal func initializeWithNilSort() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        sort: nil
      )

      #expect(config.sort == nil)
    }

    @Test("QueryConfig initializes with ascending sort")
    internal func initializeWithAscendingSort() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        sort: (field: "createdAt", order: .ascending)
      )

      #expect(config.sort?.field == "createdAt")
      #expect(config.sort?.order == .ascending)
    }

    @Test("QueryConfig initializes with descending sort")
    internal func initializeWithDescendingSort() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        sort: (field: "updatedAt", order: .descending)
      )

      #expect(config.sort?.field == "updatedAt")
      #expect(config.sort?.order == .descending)
    }

    @Test("QueryConfig handles sort on different field names")
    internal func handleSortOnDifferentFields() async throws {
      let baseConfig = try await MistDemoConfig()

      let config1 = QueryConfig(base: baseConfig, sort: (field: "title", order: .ascending))
      #expect(config1.sort?.field == "title")

      let config2 = QueryConfig(base: baseConfig, sort: (field: "priority", order: .descending))
      #expect(config2.sort?.field == "priority")

      let config3 = QueryConfig(base: baseConfig, sort: (field: "status_code", order: .ascending))
      #expect(config3.sort?.field == "status_code")
    }
  }
}
