//
//  CommandIntegrationTests+CreateCommandIntegration.swift
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

extension CommandIntegrationTests {
  @Suite("CreateCommand Integration")
  internal struct CreateCommandIntegration {
    private static func createTestConfig() async throws -> MistDemoConfig {
      try await MistDemoConfig()
    }

    @Test("CreateCommand with parsed fields")
    internal func createCommandWithParsedFields() async throws {
      let baseConfig = try await Self.createTestConfig()
      let fields = [
        try Field(parsing: "title:string:Integration Test Note"),
        try Field(parsing: "priority:int64:8"),
        try Field(parsing: "progress:double:0.85"),
      ]

      let config = CreateConfig(
        base: baseConfig,
        zone: "_defaultZone",
        recordName: "test-record-123",
        fields: fields
      )

      _ = CreateCommand(config: config)

      // Verify create configuration
      #expect(CreateCommand.commandName == "create")
      #expect(config.fields.count == 3)
      #expect(config.recordName == "test-record-123")

      // Verify field parsing
      let titleField = config.fields.first { $0.name == "title" }
      #expect(titleField?.type == .string)
      #expect(titleField?.value == "Integration Test Note")
    }

    @Test("CreateCommand field type validation")
    internal func createCommandFieldTypeValidation() async throws {
      let baseConfig = try await Self.createTestConfig()

      // Test different field types
      let stringField = try Field(parsing: "description:string:This is a test description")
      let intField = try Field(parsing: "count:int64:42")
      let doubleField = try Field(parsing: "rating:double:4.5")
      let timestampField = try Field(parsing: "deadline:timestamp:2026-12-31T23:59:59Z")

      let config = CreateConfig(
        base: baseConfig,
        zone: "_defaultZone",
        recordName: nil,
        fields: [stringField, intField, doubleField, timestampField]
      )

      _ = CreateCommand(config: config)

      #expect(config.fields.count == 4)

      // Verify each field type
      let fieldTypes = config.fields.map(\.type)
      #expect(fieldTypes.contains(.string))
      #expect(fieldTypes.contains(.int64))
      #expect(fieldTypes.contains(.double))
      #expect(fieldTypes.contains(.timestamp))
    }
  }
}
