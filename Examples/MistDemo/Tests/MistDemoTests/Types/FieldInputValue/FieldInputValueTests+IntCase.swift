//
//  FieldInputValueTests+IntCase.swift
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

extension FieldInputValueTests {
  @Suite("Int Case")
  internal struct IntCase {
    @Test("Int case converts to int64 type")
    internal func intCaseConvertsToInt64Type() throws {
      let input = FieldInputValue.int(42)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .int64)
      #expect(value == "42")
    }

    @Test("Int case with zero")
    internal func intCaseWithZero() throws {
      let input = FieldInputValue.int(0)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .int64)
      #expect(value == "0")
    }

    @Test("Int case with negative number")
    internal func intCaseWithNegativeNumber() throws {
      let input = FieldInputValue.int(-123)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .int64)
      #expect(value == "-123")
    }

    @Test("Int case with large positive number")
    internal func intCaseWithLargePositiveNumber() throws {
      let input = FieldInputValue.int(Int.max)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .int64)
      #expect(value == String(Int.max))
    }

    @Test("Int case with large negative number")
    internal func intCaseWithLargeNegativeNumber() throws {
      let input = FieldInputValue.int(Int.min)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .int64)
      #expect(value == String(Int.min))
    }
  }
}
