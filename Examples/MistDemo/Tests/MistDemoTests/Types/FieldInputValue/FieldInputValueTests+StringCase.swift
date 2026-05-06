//
//  FieldInputValueTests+StringCase.swift
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

import Foundation
import Testing

@testable import MistDemoKit

extension FieldInputValueTests {
  @Suite("String Case")
  internal struct StringCase {
    @Test("String case converts to string type")
    internal func stringCaseConvertsToStringType() throws {
      let input = FieldInputValue.string("Hello World")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "Hello World")
    }

    @Test("String case with empty string")
    internal func stringCaseWithEmptyString() throws {
      let input = FieldInputValue.string("")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "")
    }

    @Test("String case with special characters")
    internal func stringCaseWithSpecialCharacters() throws {
      let input = FieldInputValue.string("!@#$%^&*()")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "!@#$%^&*()")
    }

    @Test("String case with Unicode")
    internal func stringCaseWithUnicode() throws {
      let input = FieldInputValue.string("こんにちは")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "こんにちは")
    }

    @Test("String case with emoji")
    internal func stringCaseWithEmoji() throws {
      let input = FieldInputValue.string("👍🎉")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "👍🎉")
    }
  }
}
