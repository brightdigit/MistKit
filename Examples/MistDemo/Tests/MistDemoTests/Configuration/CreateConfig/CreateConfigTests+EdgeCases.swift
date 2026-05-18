//
//  CreateConfigTests+EdgeCases.swift
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

extension CreateConfigTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("CreateConfig handles special characters in zone name")
    internal func handleSpecialCharactersInZone() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(
        base: baseConfig,
        zone: "zone_with-special.chars"
      )

      #expect(config.zone == "zone_with-special.chars")
    }

    @Test("CreateConfig handles special characters in record type")
    internal func handleSpecialCharactersInRecordType() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(
        base: baseConfig,
        recordType: "Record_Type-123"
      )

      #expect(config.recordType == "Record_Type-123")
    }

    @Test("CreateConfig handles special characters in record name")
    internal func handleSpecialCharactersInRecordName() async throws {
      let baseConfig = try await MistDemoConfig()
      let config = CreateConfig(
        base: baseConfig,
        recordName: "record-name_with.special@chars"
      )

      #expect(config.recordName == "record-name_with.special@chars")
    }

    @Test("CreateConfig handles field with empty string value")
    internal func handleFieldWithEmptyValue() async throws {
      let baseConfig = try await MistDemoConfig()
      let field = Field(name: "emptyField", type: .string, value: "")
      let config = CreateConfig(
        base: baseConfig,
        fields: [field]
      )

      #expect(config.fields.count == 1)
      #expect(config.fields[0].value.isEmpty)
    }

    @Test("CreateConfig handles field with whitespace value")
    internal func handleFieldWithWhitespaceValue() async throws {
      let baseConfig = try await MistDemoConfig()
      let field = Field(name: "whitespaceField", type: .string, value: "   ")
      let config = CreateConfig(
        base: baseConfig,
        fields: [field]
      )

      #expect(config.fields.count == 1)
      #expect(config.fields[0].value == "   ")
    }

    @Test("CreateConfig handles very long field value")
    internal func handleVeryLongFieldValue() async throws {
      let baseConfig = try await MistDemoConfig()
      let longValue = String(repeating: "a", count: 1_000)
      let field = Field(name: "longField", type: .string, value: longValue)
      let config = CreateConfig(
        base: baseConfig,
        fields: [field]
      )

      #expect(config.fields.count == 1)
      #expect(config.fields[0].value.count == 1_000)
    }

    @Test("CreateConfig handles many fields")
    internal func handleManyFields() async throws {
      let baseConfig = try await MistDemoConfig()
      let fields = (0..<20).map { index in
        Field(name: "field\(index)", type: .string, value: "value\(index)")
      }
      let config = CreateConfig(
        base: baseConfig,
        fields: fields
      )

      #expect(config.fields.count == 20)
      #expect(config.fields[0].name == "field0")
      #expect(config.fields[19].name == "field19")
    }
  }
}
