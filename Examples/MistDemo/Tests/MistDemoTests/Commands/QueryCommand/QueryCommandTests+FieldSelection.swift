//
//  QueryCommandTests+FieldSelection.swift
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

extension QueryCommandTests {
  @Suite("Field Selection")
  internal struct FieldSelection {
    @Test("Field selection with nil returns all fields")
    internal func fieldSelectionNilReturnsAll() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = QueryConfig(base: baseConfig, fields: nil)

      #expect(config.fields == nil)
    }

    @Test("Field selection with specific fields")
    internal func fieldSelectionWithSpecificFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = ["title", "content", "createdAt"]
      let config = QueryConfig(base: baseConfig, fields: fields)

      #expect(config.fields?.count == 3)
      #expect(config.fields?.contains("title") == true)
      #expect(config.fields?.contains("content") == true)
      #expect(config.fields?.contains("createdAt") == true)
    }
  }
}
