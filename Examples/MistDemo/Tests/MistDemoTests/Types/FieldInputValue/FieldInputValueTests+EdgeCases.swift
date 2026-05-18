//
//  FieldInputValueTests+EdgeCases.swift
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
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("String case preserves whitespace")
    internal func stringCasePreservesWhitespace() throws {
      let input = FieldInputValue.string("  spaces  ")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "  spaces  ")
    }

    @Test("String case with newlines")
    internal func stringCaseWithNewlines() throws {
      let input = FieldInputValue.string("line1\nline2")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "line1\nline2")
    }

    @Test("String case with tabs")
    internal func stringCaseWithTabs() throws {
      let input = FieldInputValue.string("col1\tcol2")
      let (type, value) = try input.toFieldComponents()

      #expect(type == .string)
      #expect(value == "col1\tcol2")
    }

    @Test("Double case preserves precision")
    internal func doubleCasePreservesPrecision() throws {
      let input = FieldInputValue.double(3.141592653589793)
      let (type, value) = try input.toFieldComponents()

      #expect(type == .double)
      // String should contain most of the precision
      #expect(value.contains("3.14"))
    }

    @Test("Multiple conversions of same value produce consistent results")
    internal func multipleConversionsProduceConsistentResults() throws {
      let input = FieldInputValue.int(42)

      let (type1, value1) = try input.toFieldComponents()
      let (type2, value2) = try input.toFieldComponents()

      #expect(type1 == type2)
      #expect(value1 == value2)
    }
  }
}
