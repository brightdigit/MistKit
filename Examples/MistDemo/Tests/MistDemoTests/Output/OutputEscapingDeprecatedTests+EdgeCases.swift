//
//  OutputEscapingDeprecatedTests+EdgeCases.swift
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

extension OutputEscapingDeprecatedTests {
  @Suite("Edge Cases")
  internal struct EdgeCases {
    @Test("CSV escape handles unicode")
    internal func csvEscapeUnicode() {
      let input = "Hello 🌍 World"
      let result = OutputEscaping.csvEscape(input)
      #expect(result == "Hello 🌍 World")
    }

    @Test("YAML escape handles unicode")
    internal func yamlEscapeUnicode() {
      let input = "Hello 🌍 World"
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == "Hello 🌍 World")
    }

    @Test("All escapers handle very long strings")
    internal func escapeVeryLongStrings() {
      let input = String(repeating: "a", count: 10_000)

      let csv = OutputEscaping.csvEscape(input)
      #expect(csv == input)

      let yaml = OutputEscaping.yamlEscape(input)
      #expect(yaml == input)

      let json = OutputEscaping.jsonEscape(input)
      #expect(json == input)
    }
  }
}
