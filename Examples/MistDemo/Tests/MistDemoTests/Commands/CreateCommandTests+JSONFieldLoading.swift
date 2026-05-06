//
//  CreateCommandTests+JSONFieldLoading.swift
//  MistDemoTests
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

extension CreateCommandTests {
  @Suite("JSON Field Loading")
  internal struct JSONFieldLoading {
    @Test("Load fields from JSON dictionary")
    internal func loadFieldsFromJSONDictionary() async throws {
      let json = """
        {
            "title": "Test Note",
            "priority": 5,
            "progress": 0.75,
            "isComplete": true,
            "tags": ["work", "important"]
        }
        """

      let data = Data(json.utf8)
      let dictionary = try JSONSerialization.jsonObject(with: data) as? [String: Any]

      #expect(dictionary != nil)
      #expect(dictionary?["title"] as? String == "Test Note")
      #expect(dictionary?["priority"] as? Int == 5)
      #expect(dictionary?["progress"] as? Double == 0.75)
    }

    @Test("Convert JSON values to Field objects")
    internal func convertJSONValuesToFields() {
      let jsonValues: [String: Any] = [
        "title": "Test Note",
        "priority": 5,
        "progress": 0.75,
        "createdAt": "2026-01-29T12:00:00Z",
      ]

      var fields: [Field] = []

      for (key, value) in jsonValues {
        let field: Field
        switch value {
        case let stringValue as String:
          if stringValue.contains("T") && stringValue.contains("Z") {
            field = Field(name: key, type: .timestamp, value: stringValue)
          } else {
            field = Field(name: key, type: .string, value: stringValue)
          }
        case let intValue as Int:
          field = Field(name: key, type: .int64, value: String(intValue))
        case let doubleValue as Double:
          field = Field(name: key, type: .double, value: String(doubleValue))
        default:
          field = Field(name: key, type: .string, value: String(describing: value))
        }
        fields.append(field)
      }

      #expect(fields.count == 4)
      #expect(fields.contains { $0.name == "title" && $0.type == .string })
      #expect(fields.contains { $0.name == "priority" && $0.type == .int64 })
      #expect(fields.contains { $0.name == "progress" && $0.type == .double })
      #expect(fields.contains { $0.name == "createdAt" && $0.type == .timestamp })
    }
  }
}
