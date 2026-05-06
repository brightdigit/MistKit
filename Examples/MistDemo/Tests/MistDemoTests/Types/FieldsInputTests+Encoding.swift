//
//  FieldsInputTests+Encoding.swift
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
  @Suite("Encoding")
  internal struct Encoding {
    @Test("Encode and decode string field")
    internal func encodeDecodeStringField() throws {
      let json = """
        {
            "name": "Test"
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

      let encoded = try JSONEncoder().encode(fieldsInput)
      let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
      let fields = try decoded.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "name")
      #expect(fields[0].value == "Test")
    }

    @Test("Encode and decode integer field")
    internal func encodeDecodeIntField() throws {
      let json = """
        {
            "count": 100
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

      let encoded = try JSONEncoder().encode(fieldsInput)
      let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
      let fields = try decoded.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "count")
      #expect(fields[0].type == .int64)
      #expect(fields[0].value == "100")
    }

    @Test("Encode and decode multiple fields")
    internal func encodeDecodeMultipleFields() throws {
      let json = """
        {
            "title": "Item",
            "quantity": 3,
            "price": 15.50
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)

      let encoded = try JSONEncoder().encode(fieldsInput)
      let decoded = try JSONDecoder().decode(FieldsInput.self, from: encoded)
      let fields = try decoded.toFields()

      #expect(fields.count == 3)
    }
  }
}
