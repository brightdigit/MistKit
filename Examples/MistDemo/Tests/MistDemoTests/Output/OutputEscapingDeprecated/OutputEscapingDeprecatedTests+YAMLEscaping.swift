//
//  OutputEscapingDeprecatedTests+YAMLEscaping.swift
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
  @Suite("YAML Escaping")
  internal struct YAMLEscaping {
    @Test("YAML escape handles simple strings")
    internal func yamlEscapeSimpleString() {
      let input = "simple text without special chars"
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == input)
    }

    @Test("YAML escape handles empty strings")
    internal func yamlEscapeEmpty() {
      let input = ""
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == "\"\"")
    }

    @Test("YAML escape handles special characters")
    internal func yamlEscapeSpecialChars() {
      let testCases: [(String, String)] = [
        (":", "\":\""),
        ("#comment", "\"#comment\""),
        ("@value", "\"@value\""),
        ("[array]", "\"[array]\""),
        ("{object}", "\"{object}\""),
      ]

      for (input, expected) in testCases {
        let result = OutputEscaping.yamlEscape(input)
        #expect(result == expected, "Failed for input: \(input)")
      }
    }

    @Test("YAML escape handles boolean-like strings")
    internal func yamlEscapeBooleans() {
      let boolLike = ["yes", "no", "true", "false", "on", "off", "YES", "NO", "True", "False"]

      for input in boolLike {
        let result = OutputEscaping.yamlEscape(input)
        #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
      }
    }

    @Test("YAML escape handles null-like strings")
    internal func yamlEscapeNull() {
      let nullLike = ["null", "NULL", "Null", "~"]

      for input in nullLike {
        let result = OutputEscaping.yamlEscape(input)
        #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
      }
    }

    @Test("YAML escape handles number-like strings")
    internal func yamlEscapeNumbers() {
      let numbers = ["123", "45.67", "0", "-42", "3.14159"]

      for input in numbers {
        let result = OutputEscaping.yamlEscape(input)
        #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
      }
    }

    @Test("YAML escape handles multiline strings with block scalar")
    internal func yamlEscapeMultiline() {
      let input = "line 1\nline 2\nline 3"
      let result = OutputEscaping.yamlEscape(input)

      #expect(result.hasPrefix("|\n"))
      #expect(result.contains("    line 1"))
      #expect(result.contains("    line 2"))
      #expect(result.contains("    line 3"))
    }

    @Test("YAML escape handles strings with leading whitespace")
    internal func yamlEscapeLeadingWhitespace() {
      let input = "  leading spaces"
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.hasPrefix("\""))
    }

    @Test("YAML escape handles strings with trailing whitespace")
    internal func yamlEscapeTrailingWhitespace() {
      let input = "trailing spaces  "
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.hasPrefix("\""))
    }

    @Test("YAML escape handles backslashes")
    internal func yamlEscapeBackslash() {
      let input = "path\\to\\file"
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == "\"path\\\\to\\\\file\"")
    }

    @Test("YAML escape handles quotes")
    internal func yamlEscapeQuotes() {
      let input = "text with \"quotes\""
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == "\"text with \\\"quotes\\\"\"")
    }

    @Test("YAML escape handles tabs")
    internal func yamlEscapeTabs() {
      let input = "text\twith\ttabs"
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.contains("\\t"))
    }
  }
}
