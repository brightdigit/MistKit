//
//  FieldTests+BasicParsing.swift
//  MistDemo
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
internal import Testing

@testable import MistDemoKit

extension FieldTests {
  @Suite("Basic Parsing")
  internal struct BasicParsing {
    @Test("Parse basic string field")
    internal func parseBasicStringField() throws {
      let field = try Field(parsing: "title:string:Hello World")

      #expect(field.name == "title")
      #expect(field.type == .string)
      #expect(field.value == "Hello World")
    }

    @Test("Parse int64 field")
    internal func parseInt64Field() throws {
      let field = try Field(parsing: "count:int64:42")

      #expect(field.name == "count")
      #expect(field.type == .int64)
      #expect(field.value == "42")
    }

    @Test("Parse double field")
    internal func parseDoubleField() throws {
      let field = try Field(parsing: "price:double:19.99")

      #expect(field.name == "price")
      #expect(field.type == .double)
      #expect(field.value == "19.99")
    }

    @Test("Parse timestamp field")
    internal func parseTimestampField() throws {
      let field = try Field(parsing: "createdAt:timestamp:2024-01-15T10:30:00Z")

      #expect(field.name == "createdAt")
      #expect(field.type == .timestamp)
      #expect(field.value == "2024-01-15T10:30:00Z")
    }
  }
}
