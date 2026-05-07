//
//  FieldsInputTests+MultipleFields.swift
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

extension FieldsInputTests {
  @Suite("Multiple Fields")
  internal struct MultipleFields {
    @Test("Decode multiple mixed type fields")
    internal func decodeMultipleFields() throws {
      let json = """
        {
          "title": "Test Item",
          "count": 5,
          "price": 9.99,
          "active": true
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 4)

      let fieldsByName = Dictionary(uniqueKeysWithValues: fields.map { ($0.name, $0) })

      #expect(fieldsByName["title"]?.type == .string)
      #expect(fieldsByName["title"]?.value == "Test Item")

      #expect(fieldsByName["count"]?.type == .int64)
      #expect(fieldsByName["count"]?.value == "5")

      #expect(fieldsByName["price"]?.type == .double)
      #expect(fieldsByName["price"]?.value == "9.99")

      #expect(fieldsByName["active"]?.type == .string)
      #expect(fieldsByName["active"]?.value == "true")
    }

    @Test("Decode empty object")
    internal func decodeEmptyObject() throws {
      let json = "{}"
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.isEmpty)
    }
  }
}
