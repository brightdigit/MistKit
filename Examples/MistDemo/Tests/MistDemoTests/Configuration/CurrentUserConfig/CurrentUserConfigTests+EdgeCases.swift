//
//  CurrentUserConfigTests+EdgeCases.swift
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

extension CurrentUserConfigTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("CurrentUserConfig handles single character field name")
    func handleSingleCharacterFieldName() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: ["x"]
      )

      #expect(config.fields?.count == 1)
      #expect(config.fields?[0] == "x")
    }

    @Test("CurrentUserConfig handles fields with special characters")
    func handleFieldsWithSpecialCharacters() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: ["field_name", "field-with-dash", "field.with.dot"]
      )

      #expect(config.fields?.count == 3)
      #expect(config.fields?[0] == "field_name")
      #expect(config.fields?[1] == "field-with-dash")
      #expect(config.fields?[2] == "field.with.dot")
    }

    @Test("CurrentUserConfig handles very long field name")
    func handleVeryLongFieldName() async throws {
      let baseConfig = try await MistDemoConfig()
      let longFieldName = String(repeating: "a", count: 100)
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: [longFieldName]
      )

      #expect(config.fields?.count == 1)
      #expect(config.fields?[0].count == 100)
    }

    @Test("CurrentUserConfig handles many fields")
    func handleManyFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = (0..<20).map { "field\($0)" }
      let config = CurrentUserConfig(
        base: baseConfig,
        fields: fields
      )

      #expect(config.fields?.count == 20)
      #expect(config.fields?[0] == "field0")
      #expect(config.fields?[19] == "field19")
    }
  }
}
