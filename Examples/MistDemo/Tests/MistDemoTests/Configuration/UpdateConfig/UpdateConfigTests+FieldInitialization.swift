//
//  UpdateConfigTests+FieldInitialization.swift
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

extension UpdateConfigTests {
  @Suite("Field Initialization")
  internal struct FieldInitialization {
    @Test("UpdateConfig initializes with empty fields")
    internal func initializeWithEmptyFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: [])

      #expect(config.fields.isEmpty)
    }

    @Test("UpdateConfig initializes with single field")
    internal func initializeWithSingleField() async throws {
      let baseConfig = try await MistDemoConfig()
      let field = Field(name: "title", type: .string, value: "Updated Title")
      let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: [field])

      #expect(config.fields.count == 1)
      #expect(config.fields[0].name == "title")
      #expect(config.fields[0].type == .string)
      #expect(config.fields[0].value == "Updated Title")
    }

    @Test("UpdateConfig initializes with multiple fields of various types")
    internal func initializeWithMultipleFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "title", type: .string, value: "New Title"),
        Field(name: "count", type: .int64, value: "42"),
        Field(name: "ratio", type: .double, value: "3.14"),
      ]
      let config = UpdateConfig(base: baseConfig, recordName: "rec1", fields: fields)

      #expect(config.fields.count == 3)
      #expect(config.fields[0].type == .string)
      #expect(config.fields[1].type == .int64)
      #expect(config.fields[2].type == .double)
    }
  }
}
