//
//  DynamicKeyTests+CodingKeyConformance.swift
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

extension DynamicKeyTests {
  @Suite("CodingKey Protocol Conformance")
  internal struct CodingKeyConformance {
    @Test("Use DynamicKey in decoding container")
    internal func useInDecodingContainer() throws {
      let json = """
        {
          "dynamicField": "value",
          "anotherField": 123
        }
        """
      let data = Data(json.utf8)

      struct TestWrapper: Decodable {
        let fields: [String: String]

        init(from decoder: any Decoder) throws {
          let container = try decoder.container(keyedBy: DynamicKey.self)
          var fields: [String: String] = [:]

          for key in container.allKeys {
            if let value = try? container.decode(String.self, forKey: key) {
              fields[key.stringValue] = value
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
              fields[key.stringValue] = String(intValue)
            }
          }

          self.fields = fields
        }
      }

      let decoded = try JSONDecoder().decode(TestWrapper.self, from: data)
      #expect(decoded.fields["dynamicField"] == "value")
      #expect(decoded.fields["anotherField"] == "123")
    }

    @Test("Use DynamicKey in encoding container")
    internal func useInEncodingContainer() throws {
      struct TestWrapper: Encodable {
        let fields: [String: String]

        func encode(to encoder: any Encoder) throws {
          var container = encoder.container(keyedBy: DynamicKey.self)

          for (key, value) in fields {
            guard let dynamicKey = DynamicKey(stringValue: key) else { continue }
            try container.encode(value, forKey: dynamicKey)
          }
        }
      }

      let wrapper = TestWrapper(fields: ["field1": "value1", "field2": "value2"])
      let data = try JSONEncoder().encode(wrapper)
      let json = try JSONSerialization.jsonObject(with: data) as? [String: String]

      #expect(json?["field1"] == "value1")
      #expect(json?["field2"] == "value2")
    }
  }
}
