//
//  FieldsInputTests+StringFieldDecoding.swift
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
  @Suite("String Field Decoding")
  internal struct StringFieldDecoding {
    @Test("Decode string field")
    internal func decodeStringField() throws {
      let json = """
        {
            "title": "Hello World"
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "title")
      #expect(fields[0].type == .string)
      #expect(fields[0].value == "Hello World")
    }

    @Test("Decode empty string field")
    internal func decodeEmptyStringField() throws {
      let json = """
        {
            "description": ""
        }
        """
      let data = Data(json.utf8)
      let fieldsInput = try JSONDecoder().decode(FieldsInput.self, from: data)
      let fields = try fieldsInput.toFields()

      #expect(fields.count == 1)
      #expect(fields[0].name == "description")
      #expect(fields[0].type == .string)
      #expect(fields[0].value == "")
    }
  }
}
