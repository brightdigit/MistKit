//
//  FieldTests+ErrorCases.swift
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
  @Suite("Error Cases")
  internal struct ErrorCases {
    @Test("Parse field with empty name throws error")
    internal func parseFieldWithEmptyName() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: ":string:value")
      }
    }

    @Test("Parse field with whitespace-only name throws error")
    internal func parseFieldWithWhitespaceOnlyName() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: "   :string:value")
      }
    }

    @Test("Parse field with unknown type throws error")
    internal func parseFieldWithUnknownType() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: "title:unknown:value")
      }
    }

    @Test("Parse field with invalid format (too few parts)")
    internal func parseFieldWithTooFewParts() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: "title:string")
      }
    }

    @Test("Parse field with invalid format (one part)")
    internal func parseFieldWithOnePart() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: "title")
      }
    }

    @Test("Parse field with invalid format (empty string)")
    internal func parseFieldWithEmptyString() {
      #expect(throws: FieldParsingError.self) {
        try Field(parsing: "")
      }
    }
  }
}
