//
//  QueryConfigTests+EdgeCases.swift
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
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("QueryConfig handles special characters in filters")
    internal func handleSpecialCharactersInFilters() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        filters: ["name='O'Brien'", "email~='@example.com'"]
      )

      #expect(config.filters.count == 2)
      #expect(config.filters[0] == "name='O'Brien'")
    }

    @Test("QueryConfig handles zero limit")
    internal func handleZeroLimit() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        limit: 0
      )

      #expect(config.limit == 0)
    }

    @Test("QueryConfig handles fields with special characters")
    internal func handleFieldsWithSpecialCharacters() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(
        base: baseConfig,
        fields: ["field_name", "field-with-dash", "field.with.dot"]
      )

      #expect(config.fields?.count == 3)
      #expect(config.fields?[0] == "field_name")
      #expect(config.fields?[1] == "field-with-dash")
      #expect(config.fields?[2] == "field.with.dot")
    }
  }
}
