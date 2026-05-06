//
//  OutputEscapingDeprecatedTests+JSONEscaping.swift
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
  @Suite("JSON Escaping")
  internal struct JSONEscaping {
    @Test("JSON escape handles simple strings")
    internal func jsonEscapeSimpleString() {
      let input = "simple text"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "simple text")
    }

    @Test("JSON escape handles backslashes")
    internal func jsonEscapeBackslash() {
      let input = "path\\to\\file"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "path\\\\to\\\\file")
    }

    @Test("JSON escape handles quotes")
    internal func jsonEscapeQuotes() {
      let input = "text with \"quotes\""
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "text with \\\"quotes\\\"")
    }

    @Test("JSON escape handles newlines")
    internal func jsonEscapeNewlines() {
      let input = "line 1\nline 2"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "line 1\\nline 2")
    }

    @Test("JSON escape handles carriage returns")
    internal func jsonEscapeCarriageReturns() {
      let input = "text\rwith\rCR"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "text\\rwith\\rCR")
    }

    @Test("JSON escape handles tabs")
    internal func jsonEscapeTabs() {
      let input = "text\twith\ttabs"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "text\\twith\\ttabs")
    }

    @Test("JSON escape handles form feed")
    internal func jsonEscapeFormFeed() {
      let input = "text\u{000C}with\u{000C}FF"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "text\\fwith\\fFF")
    }

    @Test("JSON escape handles backspace")
    internal func jsonEscapeBackspace() {
      let input = "text\u{0008}with\u{0008}BS"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "text\\bwith\\bBS")
    }

    @Test("JSON escape handles all control characters")
    internal func jsonEscapeAllControls() {
      let input = "\\\"\n\r\t\u{000C}\u{0008}"
      let result = OutputEscaping.jsonEscape(input)
      #expect(result == "\\\\\\\"\\n\\r\\t\\f\\b")
    }

    @Test("JSON escape handles empty string")
    internal func jsonEscapeEmpty() {
      let input = ""
      let result = OutputEscaping.jsonEscape(input)
      #expect(result.isEmpty)
    }

    @Test("JSON escape handles unicode")
    internal func jsonEscapeUnicode() {
      let input = "Hello 🌍 World"
      let result = OutputEscaping.jsonEscape(input)
      // Unicode should pass through (JSONEncoder handles this)
      #expect(result == "Hello 🌍 World")
    }
  }
}
