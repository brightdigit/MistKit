//
//  QueryCommandTests+MultipleFilters.swift
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
  @Suite("Multiple Filters")
  internal struct MultipleFilters {
    @Test("Multiple filters are preserved")
    internal func multipleFiltersPreserved() async throws {
      let baseConfig = try await MistDemoConfig()
      let filters = [
        "title:contains:Test",
        "priority:gt:5",
        "status:eq:active",
      ]
      let config = QueryConfig(base: baseConfig, filters: filters)

      #expect(config.filters.count == 3)
      #expect(config.filters[0] == "title:contains:Test")
      #expect(config.filters[1] == "priority:gt:5")
      #expect(config.filters[2] == "status:eq:active")
    }
  }
}
