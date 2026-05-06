//
//  CreateCommandTests+FieldParsing.swift
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
import Testing

@testable import MistDemoKit

extension CreateCommandTests {
  @Suite("Field Parsing")
  internal struct FieldParsing {
    @Test("Parse string field")
    internal func parseStringField() async throws {
      let field = try Field(parsing: "title:string:My Note")

      #expect(field.name == "title")
      #expect(field.type == .string)
      #expect(field.value == "My Note")
    }

    @Test("Parse int64 field")
    internal func parseInt64Field() async throws {
      let field = try Field(parsing: "priority:int64:5")

      #expect(field.name == "priority")
      #expect(field.type == .int64)
      #expect(field.value == "5")
    }

    @Test("Parse double field")
    internal func parseDoubleField() async throws {
      let field = try Field(parsing: "progress:double:0.75")

      #expect(field.name == "progress")
      #expect(field.type == .double)
      #expect(field.value == "0.75")
    }

    @Test("Parse timestamp field")
    internal func parseTimestampField() async throws {
      let field = try Field(parsing: "dueDate:timestamp:2026-02-01T09:00:00Z")

      #expect(field.name == "dueDate")
      #expect(field.type == .timestamp)
      #expect(field.value == "2026-02-01T09:00:00Z")
    }

    @Test("Parse field with colon in value")
    internal func parseFieldWithColonInValue() async throws {
      let field = try Field(parsing: "url:string:https://example.com:8080")

      #expect(field.name == "url")
      #expect(field.type == .string)
      #expect(field.value == "https://example.com:8080")
    }

    @Test("Parse field with spaces in value")
    internal func parseFieldWithSpacesInValue() async throws {
      let field = try Field(parsing: "description:string:This is a long description with spaces")

      #expect(field.name == "description")
      #expect(field.type == .string)
      #expect(field.value == "This is a long description with spaces")
    }
  }
}
