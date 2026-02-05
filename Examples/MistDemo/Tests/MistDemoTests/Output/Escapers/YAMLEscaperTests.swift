//
//  YAMLEscaperTests.swift
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

@testable import MistDemo

@Suite("YAMLEscaper Tests - YAML String Formatting")
struct YAMLEscaperTests {
    let escaper = YAMLEscaper()

    // MARK: - Plain String Tests

    @Test("Plain string without special characters needs no escaping")
    func plainStringNoEscaping() {
        let input = "Hello World"
        let output = escaper.escape(input)
        #expect(output == "Hello World")
    }

    @Test("Simple alphanumeric string")
    func alphanumericString() {
        let input = "test123"
        let output = escaper.escape(input)
        #expect(output == "test123")
    }

    // MARK: - Empty String Tests

    @Test("Empty string is quoted")
    func emptyStringIsQuoted() {
        let input = ""
        let output = escaper.escape(input)
        #expect(output == "\"\"")
    }

    // MARK: - Boolean-like String Tests (YAML Reserved Words)

    @Test("String 'yes' is quoted")
    func yesIsQuoted() {
        let input = "yes"
        let output = escaper.escape(input)
        #expect(output == "\"yes\"")
    }

    @Test("String 'no' is quoted")
    func noIsQuoted() {
        let input = "no"
        let output = escaper.escape(input)
        #expect(output == "\"no\"")
    }

    @Test("String 'true' is quoted")
    func trueIsQuoted() {
        let input = "true"
        let output = escaper.escape(input)
        #expect(output == "\"true\"")
    }

    @Test("String 'false' is quoted")
    func falseIsQuoted() {
        let input = "false"
        let output = escaper.escape(input)
        #expect(output == "\"false\"")
    }

    @Test("String 'on' is quoted")
    func onIsQuoted() {
        let input = "on"
        let output = escaper.escape(input)
        #expect(output == "\"on\"")
    }

    @Test("String 'off' is quoted")
    func offIsQuoted() {
        let input = "off"
        let output = escaper.escape(input)
        #expect(output == "\"off\"")
    }

    @Test("String 'YES' (uppercase) is quoted")
    func yesUppercaseIsQuoted() {
        let input = "YES"
        let output = escaper.escape(input)
        #expect(output == "\"YES\"")
    }

    @Test("String 'True' (capitalized) is quoted")
    func trueCapitalizedIsQuoted() {
        let input = "True"
        let output = escaper.escape(input)
        #expect(output == "\"True\"")
    }

    // MARK: - Null-like String Tests

    @Test("String 'null' is quoted")
    func nullIsQuoted() {
        let input = "null"
        let output = escaper.escape(input)
        #expect(output == "\"null\"")
    }

    @Test("String 'NULL' (uppercase) is quoted")
    func nullUppercaseIsQuoted() {
        let input = "NULL"
        let output = escaper.escape(input)
        #expect(output == "\"NULL\"")
    }

    @Test("String '~' (tilde) is quoted")
    func tildeIsQuoted() {
        let input = "~"
        let output = escaper.escape(input)
        #expect(output == "\"~\"")
    }

    // MARK: - Numeric String Tests

    @Test("Integer string is quoted")
    func integerStringIsQuoted() {
        let input = "123"
        let output = escaper.escape(input)
        #expect(output == "\"123\"")
    }

    @Test("Negative integer string is quoted")
    func negativeIntegerIsQuoted() {
        let input = "-456"
        let output = escaper.escape(input)
        #expect(output == "\"-456\"")
    }

    @Test("Float string is quoted")
    func floatStringIsQuoted() {
        let input = "3.14"
        let output = escaper.escape(input)
        #expect(output == "\"3.14\"")
    }

    @Test("Scientific notation string is quoted")
    func scientificNotationIsQuoted() {
        let input = "1.23e10"
        let output = escaper.escape(input)
        #expect(output == "\"1.23e10\"")
    }

    @Test("Zero string is quoted")
    func zeroIsQuoted() {
        let input = "0"
        let output = escaper.escape(input)
        #expect(output == "\"0\"")
    }

    // MARK: - Special Character Tests

    @Test("String with colon is quoted")
    func stringWithColon() {
        let input = "key:value"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
    }

    @Test("String starting with colon is quoted")
    func stringStartingWithColon() {
        let input = ":start"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
    }

    @Test("String with hash is quoted")
    func stringWithHash() {
        let input = "comment # here"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
    }

    @Test("String with brackets is quoted")
    func stringWithBrackets() {
        let input = "[array]"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
    }

    @Test("String with braces is quoted")
    func stringWithBraces() {
        let input = "{object}"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
    }

    // MARK: - Whitespace Tests

    @Test("String starting with space is quoted")
    func stringStartingWithSpace() {
        let input = " leading"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
    }

    @Test("String ending with space is quoted")
    func stringEndingWithSpace() {
        let input = "trailing "
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
    }

    @Test("String starting with tab is quoted")
    func stringStartingWithTab() {
        let input = "\tleading"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
    }

    @Test("String ending with newline is quoted")
    func stringEndingWithNewline() {
        let input = "trailing\n"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
    }

    // MARK: - Quote and Backslash Escaping Tests

    @Test("String with double quote is escaped")
    func stringWithDoubleQuote() {
        let input = "She said \"Hello\""
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.contains("\\\""))
    }

    @Test("String with backslash is escaped")
    func stringWithBackslash() {
        let input = "path\\to\\file"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.contains("\\\\"))
    }

    @Test("String with tab character is escaped in single-line mode")
    func stringWithTabEscaped() {
        let input = "before\tafter"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.contains("\\t"))
    }

    @Test("String with carriage return is escaped in single-line mode")
    func stringWithCarriageReturn() {
        let input = "before\rafter"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.contains("\\r"))
    }

    // MARK: - Multi-line String Tests (Block Scalar)

    @Test("Multi-line string uses block scalar")
    func multiLineUsesBlockScalar() {
        let input = "Line 1\nLine 2\nLine 3"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
        #expect(output.contains("Line 1"))
        #expect(output.contains("Line 2"))
        #expect(output.contains("Line 3"))
    }

    @Test("Two-line string uses block scalar")
    func twoLineUsesBlockScalar() {
        let input = "First\nSecond"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|\n"))
    }

    @Test("String with empty line in middle")
    func multiLineWithEmptyLine() {
        let input = "Before\n\nAfter"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
        #expect(output.contains("Before"))
        #expect(output.contains("After"))
    }

    @Test("Multi-line string preserves indentation context")
    func multiLinePreservesContent() {
        let input = "Line 1\nLine 2"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
        // Block scalar should have indented lines
        #expect(output.contains("    Line 1"))
        #expect(output.contains("    Line 2"))
    }

    // MARK: - Unicode and Emoji Tests

    @Test("String with emoji needs no escaping if plain")
    func plainStringWithEmoji() {
        let input = "Hello👋World"
        let output = escaper.escape(input)
        #expect(output == "Hello👋World")
    }

    @Test("String with unicode characters")
    func unicodeCharacters() {
        let input = "Café"
        let output = escaper.escape(input)
        #expect(output == "Café")
    }

    @Test("String with Japanese characters")
    func japaneseCharacters() {
        let input = "こんにちは"
        let output = escaper.escape(input)
        #expect(output == "こんにちは")
    }

    // MARK: - Complex Edge Cases

    @Test("String that looks like YAML but isn't")
    func yamlLikeString() {
        let input = "yes this is true"
        let output = escaper.escape(input)
        // Should not be quoted because "yes" is part of a larger string
        #expect(output == "yes this is true")
    }

    @Test("Number within text is not escaped")
    func numberWithinText() {
        let input = "test123abc"
        let output = escaper.escape(input)
        #expect(output == "test123abc")
    }

    @Test("String with special character in middle needs escaping")
    func specialCharInMiddle() {
        let input = "test:value"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
    }

    @Test("Complex multi-line with quotes and escapes")
    func complexMultiLine() {
        let input = "Line 1: \"quoted\"\nLine 2: with\\backslash"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
    }

    @Test("Single newline character")
    func singleNewline() {
        let input = "\n"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
    }

    @Test("String with only whitespace and newline")
    func whitespaceWithNewline() {
        let input = "  \n  "
        let output = escaper.escape(input)
        #expect(output.hasPrefix("|"))
    }
}
