//
//  FieldTests+ParseMultiple.swift
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

extension FieldTests {
  @Suite("parseMultiple")
  internal struct ParseMultiple {
    @Test("Parse multiple valid fields")
    func parseMultipleValidFields() throws {
      let inputs = [
        "title:string:Hello",
        "count:int64:42",
        "price:double:19.99",
      ]

      let fields = try Field.parseMultiple(inputs)

      #expect(fields.count == 3)
      #expect(fields[0].name == "title")
      #expect(fields[1].name == "count")
      #expect(fields[2].name == "price")
    }

    @Test("Parse multiple fields with empty array")
    func parseMultipleFieldsWithEmptyArray() throws {
      let fields = try Field.parseMultiple([])

      #expect(fields.isEmpty)
    }

    @Test("Parse multiple fields throws on first invalid")
    func parseMultipleFieldsThrowsOnInvalid() {
      let inputs = [
        "title:string:Hello",
        "invalid",
        "price:double:19.99",
      ]

      #expect(throws: FieldParsingError.self) {
        try Field.parseMultiple(inputs)
      }
    }
  }
}
