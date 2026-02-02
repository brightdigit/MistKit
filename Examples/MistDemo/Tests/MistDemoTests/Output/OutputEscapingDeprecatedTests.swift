//
//  OutputEscapingDeprecatedTests.swift
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
@testable import MistDemo

/// Tests for deprecated OutputEscaping APIs
/// These tests ensure backward compatibility during deprecation period
@Suite("OutputEscaping Deprecated API Tests")
struct OutputEscapingDeprecatedTests {

  // MARK: - CSV Escaping Tests

  @Test("CSV escape handles simple strings without special characters")
  func csvEscapeSimpleString() {
    let input = "simple text"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "simple text")
  }

  @Test("CSV escape handles comma")
  func csvEscapeComma() {
    let input = "text,with,commas"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"text,with,commas\"")
  }

  @Test("CSV escape handles quotes")
  func csvEscapeQuotes() {
    let input = "text with \"quotes\""
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"text with \"\"quotes\"\"\"")
  }

  @Test("CSV escape handles newlines")
  func csvEscapeNewlines() {
    let input = "text\nwith\nnewlines"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"text\nwith\nnewlines\"")
  }

  @Test("CSV escape handles tabs")
  func csvEscapeTabs() {
    let input = "text\twith\ttabs"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"text\twith\ttabs\"")
  }

  @Test("CSV escape handles carriage returns")
  func csvEscapeCarriageReturns() {
    let input = "text\rwith\rCR"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"text\rwith\rCR\"")
  }

  @Test("CSV escape handles mixed special characters")
  func csvEscapeMixed() {
    let input = "Name: \"John, Jr.\"\nAge: 30"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "\"Name: \"\"John, Jr.\"\"\nAge: 30\"")
  }

  @Test("CSV escape handles empty string")
  func csvEscapeEmpty() {
    let input = ""
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "")
  }

  @Test("CSV escape is idempotent for simple strings")
  func csvEscapeIdempotent() {
    let input = "simple text"
    let once = OutputEscaping.csvEscape(input)
    let twice = OutputEscaping.csvEscape(once)
    #expect(once == input)
    #expect(twice == "\"simple text\"")  // Now needs escaping because of quotes
  }

  // MARK: - YAML Escaping Tests

  @Test("YAML escape handles simple strings")
  func yamlEscapeSimpleString() {
    let input = "simple text without special chars"
    let result = OutputEscaping.yamlEscape(input)
    #expect(result == input)
  }

  @Test("YAML escape handles empty strings")
  func yamlEscapeEmpty() {
    let input = ""
    let result = OutputEscaping.yamlEscape(input)
    #expect(result == "\"\"")
  }

  @Test("YAML escape handles special characters")
  func yamlEscapeSpecialChars() {
    let testCases: [(String, String)] = [
      (":", "\":\""),
      ("#comment", "\"#comment\""),
      ("@value", "\"@value\""),
      ("[array]", "\"[array]\""),
      ("{object}", "\"{object}\"")
    ]

    for (input, expected) in testCases {
      let result = OutputEscaping.yamlEscape(input)
      #expect(result == expected, "Failed for input: \(input)")
    }
  }

  @Test("YAML escape handles boolean-like strings")
  func yamlEscapeBooleans() {
    let boolLike = ["yes", "no", "true", "false", "on", "off", "YES", "NO", "True", "False"]

    for input in boolLike {
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
    }
  }

  @Test("YAML escape handles null-like strings")
  func yamlEscapeNull() {
    let nullLike = ["null", "NULL", "Null", "~"]

    for input in nullLike {
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
    }
  }

  @Test("YAML escape handles number-like strings")
  func yamlEscapeNumbers() {
    let numbers = ["123", "45.67", "0", "-42", "3.14159"]

    for input in numbers {
      let result = OutputEscaping.yamlEscape(input)
      #expect(result.hasPrefix("\"") && result.hasSuffix("\""), "Should escape: \(input)")
    }
  }

  @Test("YAML escape handles multiline strings with block scalar")
  func yamlEscapeMultiline() {
    let input = "line 1\nline 2\nline 3"
    let result = OutputEscaping.yamlEscape(input)

    #expect(result.hasPrefix("|\n"))
    #expect(result.contains("    line 1"))
    #expect(result.contains("    line 2"))
    #expect(result.contains("    line 3"))
  }

  @Test("YAML escape handles strings with leading whitespace")
  func yamlEscapeLeadingWhitespace() {
    let input = "  leading spaces"
    let result = OutputEscaping.yamlEscape(input)
    #expect(result.hasPrefix("\""))
  }

  @Test("YAML escape handles strings with trailing whitespace")
  func yamlEscapeTrailingWhitespace() {
    let input = "trailing spaces  "
    let result = OutputEscaping.yamlEscape(input)
    #expect(result.hasPrefix("\""))
  }

  @Test("YAML escape handles backslashes")
  func yamlEscapeBackslash() {
    let input = "path\\to\\file"
    let result = OutputEscaping.yamlEscape(input)
    #expect(result == "\"path\\\\to\\\\file\"")
  }

  @Test("YAML escape handles quotes")
  func yamlEscapeQuotes() {
    let input = "text with \"quotes\""
    let result = OutputEscaping.yamlEscape(input)
    #expect(result == "\"text with \\\"quotes\\\"\"")
  }

  @Test("YAML escape handles tabs")
  func yamlEscapeTabs() {
    let input = "text\twith\ttabs"
    let result = OutputEscaping.yamlEscape(input)
    #expect(result.contains("\\t"))
  }

  // MARK: - JSON Escaping Tests

  @Test("JSON escape handles simple strings")
  func jsonEscapeSimpleString() {
    let input = "simple text"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "simple text")
  }

  @Test("JSON escape handles backslashes")
  func jsonEscapeBackslash() {
    let input = "path\\to\\file"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "path\\\\to\\\\file")
  }

  @Test("JSON escape handles quotes")
  func jsonEscapeQuotes() {
    let input = "text with \"quotes\""
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "text with \\\"quotes\\\"")
  }

  @Test("JSON escape handles newlines")
  func jsonEscapeNewlines() {
    let input = "line 1\nline 2"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "line 1\\nline 2")
  }

  @Test("JSON escape handles carriage returns")
  func jsonEscapeCarriageReturns() {
    let input = "text\rwith\rCR"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "text\\rwith\\rCR")
  }

  @Test("JSON escape handles tabs")
  func jsonEscapeTabs() {
    let input = "text\twith\ttabs"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "text\\twith\\ttabs")
  }

  @Test("JSON escape handles form feed")
  func jsonEscapeFormFeed() {
    let input = "text\u{000C}with\u{000C}FF"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "text\\fwith\\fFF")
  }

  @Test("JSON escape handles backspace")
  func jsonEscapeBackspace() {
    let input = "text\u{0008}with\u{0008}BS"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "text\\bwith\\bBS")
  }

  @Test("JSON escape handles all control characters")
  func jsonEscapeAllControls() {
    let input = "\\\"\n\r\t\u{000C}\u{0008}"
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "\\\\\\\"\\n\\r\\t\\f\\b")
  }

  @Test("JSON escape handles empty string")
  func jsonEscapeEmpty() {
    let input = ""
    let result = OutputEscaping.jsonEscape(input)
    #expect(result == "")
  }

  @Test("JSON escape handles unicode")
  func jsonEscapeUnicode() {
    let input = "Hello 🌍 World"
    let result = OutputEscaping.jsonEscape(input)
    // Unicode should pass through (JSONEncoder handles this)
    #expect(result == "Hello 🌍 World")
  }

  // MARK: - Edge Cases

  @Test("CSV escape handles unicode")
  func csvEscapeUnicode() {
    let input = "Hello 🌍 World"
    let result = OutputEscaping.csvEscape(input)
    #expect(result == "Hello 🌍 World")
  }

  @Test("YAML escape handles unicode")
  func yamlEscapeUnicode() {
    let input = "Hello 🌍 World"
    let result = OutputEscaping.yamlEscape(input)
    #expect(result == "Hello 🌍 World")
  }

  @Test("All escapers handle very long strings")
  func escapeVeryLongStrings() {
    let input = String(repeating: "a", count: 10000)

    let csv = OutputEscaping.csvEscape(input)
    #expect(csv == input)

    let yaml = OutputEscaping.yamlEscape(input)
    #expect(yaml == input)

    let json = OutputEscaping.jsonEscape(input)
    #expect(json == input)
  }
}
