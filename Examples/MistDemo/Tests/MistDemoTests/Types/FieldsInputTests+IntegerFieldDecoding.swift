//
//  FieldsInputTests+IntegerFieldDecoding.swift
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
  @Suite("Integer Field Decoding")
  internal struct IntegerFieldDecoding {
    @Test("Decode integer field")
    internal func decodeIntField() throws {
      let json = """
        {
            "count": 42
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "count")
      #expect(fields[0].type == .int64)
      #expect(fields[0].value == "42")
    }

    @Test("Decode negative integer field")
    internal func decodeNegativeIntField() throws {
      let json = """
        {
            "temperature": -10
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "temperature")
      #expect(fields[0].type == .int64)
      #expect(fields[0].value == "-10")
    }

    @Test("Decode zero integer field")
    internal func decodeZeroIntField() throws {
      let json = """
        {
            "balance": 0
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "balance")
      #expect(fields[0].type == .int64)
      #expect(fields[0].value == "0")
    }
  }
}
