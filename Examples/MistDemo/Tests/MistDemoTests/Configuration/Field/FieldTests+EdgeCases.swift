//
//  FieldTests+EdgeCases.swift
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
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("Parse field with empty value")
    internal func parseFieldWithEmptyValue() throws {
      let field = try Field(parsing: "title:string:")

      #expect(field.name == "title")
      #expect(field.type == .string)
      #expect(field.value.isEmpty)
    }

    @Test("Parse field with Unicode in value")
    internal func parseFieldWithUnicode() throws {
      let field = try Field(parsing: "message:string:こんにちは世界")

      #expect(field.name == "message")
      #expect(field.type == .string)
      #expect(field.value == "こんにちは世界")
    }

    @Test("Parse field with emoji in value")
    internal func parseFieldWithEmoji() throws {
      let field = try Field(parsing: "reaction:string:👍🎉🚀")

      #expect(field.name == "reaction")
      #expect(field.type == .string)
      #expect(field.value == "👍🎉🚀")
    }

    @Test("Parse field with special characters in value")
    internal func parseFieldWithSpecialCharacters() throws {
      let field = try Field(parsing: "data:string:!@#$%^&*()_+-=[]{}|;'\"<>,.?/~`")

      #expect(field.name == "data")
      #expect(field.type == .string)
      #expect(field.value == "!@#$%^&*()_+-=[]{}|;'\"<>,.?/~`")
    }

    @Test("Parse field with newline in value")
    internal func parseFieldWithNewlineInValue() throws {
      let field = try Field(parsing: "text:string:line1\nline2")

      #expect(field.name == "text")
      #expect(field.type == .string)
      #expect(field.value == "line1\nline2")
    }

    @Test("Parse field with tab in value")
    internal func parseFieldWithTabInValue() throws {
      let field = try Field(parsing: "text:string:col1\tcol2")

      #expect(field.name == "text")
      #expect(field.type == .string)
      #expect(field.value == "col1\tcol2")
    }
  }
}
