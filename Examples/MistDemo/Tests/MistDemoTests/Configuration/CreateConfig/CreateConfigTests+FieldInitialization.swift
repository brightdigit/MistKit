//
//  CreateConfigTests+FieldInitialization.swift
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

extension CreateConfigTests {
  @Suite("Field Initialization")
  internal struct FieldInitialization {
    @Test("CreateConfig initializes with empty fields")
    internal func initializeWithEmptyFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(
        base: baseConfig,
        fields: []
      )

      #expect(config.fields.isEmpty)
    }

    @Test("CreateConfig initializes with single field")
    internal func initializeWithSingleField() async throws {
      let baseConfig = try await MistDemoConfig()
      let field = Field(name: "title", type: .string, value: "Hello World")
      let config = CreateConfig(
        base: baseConfig,
        fields: [field]
      )

      #expect(config.fields.count == 1)
      #expect(config.fields[0].name == "title")
      #expect(config.fields[0].type == .string)
      #expect(config.fields[0].value == "Hello World")
    }

    @Test("CreateConfig initializes with multiple fields")
    internal func initializeWithMultipleFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "title", type: .string, value: "Test Title"),
        Field(name: "count", type: .int64, value: "42"),
        Field(name: "price", type: .double, value: "99.99"),
      ]
      let config = CreateConfig(
        base: baseConfig,
        fields: fields
      )

      #expect(config.fields.count == 3)
      #expect(config.fields[0].name == "title")
      #expect(config.fields[1].name == "count")
      #expect(config.fields[2].name == "price")
    }

    @Test("CreateConfig initializes with different field types")
    internal func initializeWithDifferentFieldTypes() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = [
        Field(name: "stringField", type: .string, value: "text"),
        Field(name: "intField", type: .int64, value: "100"),
        Field(name: "doubleField", type: .double, value: "3.14"),
        Field(name: "timestampField", type: .timestamp, value: "1234567890000"),
        Field(name: "bytesField", type: .bytes, value: "ZGF0YQ=="),
      ]
      let config = CreateConfig(
        base: baseConfig,
        fields: fields
      )

      #expect(config.fields.count == 5)
      #expect(config.fields[0].type == .string)
      #expect(config.fields[1].type == .int64)
      #expect(config.fields[2].type == .double)
      #expect(config.fields[3].type == .timestamp)
      #expect(config.fields[4].type == .bytes)
    }
  }
}
