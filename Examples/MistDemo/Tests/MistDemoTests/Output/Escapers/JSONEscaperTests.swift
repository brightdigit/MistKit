//
//  JSONEscaperTests.swift
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

@Suite("JSONEscaper Tests - JSON String Escaping")
struct JSONEscaperTests {
    let escaper = JSONEscaper()

    // MARK: - Plain String Tests

    @Test("Plain string remains unchanged")
    func plainStringUnchanged() {
        let input = "Hello World"
        let output = escaper.escape(input)
        #expect(output == "Hello World")
    }

    @Test("Alphanumeric string remains unchanged")
    func alphanumericUnchanged() {
        let input = "Test123"
        let output = escaper.escape(input)
        #expect(output == "Test123")
    }

    @Test("Empty string remains empty")
    func emptyStringRemains() {
        let input = ""
        let output = escaper.escape(input)
        #expect(output == "")
    }

    // MARK: - Backslash Escaping Tests

    @Test("Backslash is escaped")
    func backslashEscaped() {
        let input = "path\\to\\file"
        let output = escaper.escape(input)
        #expect(output == "path\\\\to\\\\file")
    }

    @Test("Single backslash")
    func singleBackslash() {
        let input = "\\"
        let output = escaper.escape(input)
        #expect(output == "\\\\")
    }

    @Test("Multiple consecutive backslashes")
    func multipleBackslashes() {
        let input = "\\\\\\"
        let output = escaper.escape(input)
        #expect(output == "\\\\\\\\\\\\")
    }

    // MARK: - Quote Escaping Tests

    @Test("Double quote is escaped")
    func doubleQuoteEscaped() {
        let input = "She said \"Hello\""
        let output = escaper.escape(input)
        #expect(output == "She said \\\"Hello\\\"")
    }

    @Test("Single double quote")
    func singleQuote() {
        let input = "\""
        let output = escaper.escape(input)
        #expect(output == "\\\"")
    }

    @Test("Multiple quotes")
    func multipleQuotes() {
        let input = "\"\"\"test\"\"\""
        let output = escaper.escape(input)
        #expect(output == "\\\"\\\"\\\"test\\\"\\\"\\\"")
    }

    // MARK: - Newline Escaping Tests

    @Test("Newline is escaped to \\n")
    func newlineEscaped() {
        let input = "Line 1\nLine 2"
        let output = escaper.escape(input)
        #expect(output == "Line 1\\nLine 2")
    }

    @Test("Multiple newlines")
    func multipleNewlines() {
        let input = "A\nB\nC"
        let output = escaper.escape(input)
        #expect(output == "A\\nB\\nC")
    }

    @Test("Consecutive newlines")
    func consecutiveNewlines() {
        let input = "Text\n\nMore"
        let output = escaper.escape(input)
        #expect(output == "Text\\n\\nMore")
    }

    // MARK: - Carriage Return Escaping Tests

    @Test("Carriage return is escaped to \\r")
    func carriageReturnEscaped() {
        let input = "Before\rAfter"
        let output = escaper.escape(input)
        #expect(output == "Before\\rAfter")
    }

    @Test("CRLF is escaped")
    func crlfEscaped() {
        let input = "Windows\r\nLine"
        let output = escaper.escape(input)
        #expect(output == "Windows\\r\\nLine")
    }

    // MARK: - Tab Escaping Tests

    @Test("Tab is escaped to \\t")
    func tabEscaped() {
        let input = "Column1\tColumn2"
        let output = escaper.escape(input)
        #expect(output == "Column1\\tColumn2")
    }

    @Test("Multiple tabs")
    func multipleTabs() {
        let input = "A\tB\tC"
        let output = escaper.escape(input)
        #expect(output == "A\\tB\\tC")
    }

    // MARK: - Form Feed Escaping Tests

    @Test("Form feed is escaped to \\f")
    func formFeedEscaped() {
        let input = "Before\u{000C}After"
        let output = escaper.escape(input)
        #expect(output == "Before\\fAfter")
    }

    // MARK: - Backspace Escaping Tests

    @Test("Backspace is escaped to \\b")
    func backspaceEscaped() {
        let input = "Before\u{0008}After"
        let output = escaper.escape(input)
        #expect(output == "Before\\bAfter")
    }

    // MARK: - Combination Tests

    @Test("Backslash and quote together")
    func backslashAndQuote() {
        let input = "path\\\"file\""
        let output = escaper.escape(input)
        #expect(output == "path\\\\\\\"file\\\"")
    }

    @Test("All escape characters together")
    func allEscapeCharacters() {
        let input = "\\\"\n\r\t\u{000C}\u{0008}"
        let output = escaper.escape(input)
        #expect(output == "\\\\\\\"\\n\\r\\t\\f\\b")
    }

    @Test("Text with mixed escape sequences")
    func mixedEscapeSequences() {
        let input = "Line 1\nTab\there\r\nQuote:\""
        let output = escaper.escape(input)
        #expect(output.contains("\\n"))
        #expect(output.contains("\\t"))
        #expect(output.contains("\\r"))
        #expect(output.contains("\\\""))
    }

    // MARK: - Unicode and Emoji Tests

    @Test("Emoji preserved without escaping")
    func emojiPreserved() {
        let input = "Hello 👋 World"
        let output = escaper.escape(input)
        #expect(output == "Hello 👋 World")
    }

    @Test("Unicode characters preserved")
    func unicodePreserved() {
        let input = "Café résumé"
        let output = escaper.escape(input)
        #expect(output == "Café résumé")
    }

    @Test("Japanese characters preserved")
    func japanesePreserved() {
        let input = "こんにちは"
        let output = escaper.escape(input)
        #expect(output == "こんにちは")
    }

    // MARK: - Edge Cases

    @Test("String with only escape characters")
    func onlyEscapeCharacters() {
        let input = "\n\r\t"
        let output = escaper.escape(input)
        #expect(output == "\\n\\r\\t")
    }

    @Test("Long string with escapes")
    func longStringWithEscapes() {
        let input = String(repeating: "\n", count: 100)
        let output = escaper.escape(input)
        #expect(output == String(repeating: "\\n", count: 100))
    }

    @Test("Normal characters not escaped")
    func normalCharactersNotEscaped() {
        let input = "!@#$%^&*()_+-=[]{}|;':,.<>?/"
        let output = escaper.escape(input)
        // Only quote should be escaped
        #expect(output.contains("\\\""))
        // Other characters should remain
        #expect(output.contains("!@#$%^&*"))
    }

    @Test("Escape sequence at start")
    func escapeAtStart() {
        let input = "\nStart"
        let output = escaper.escape(input)
        #expect(output == "\\nStart")
    }

    @Test("Escape sequence at end")
    func escapeAtEnd() {
        let input = "End\n"
        let output = escaper.escape(input)
        #expect(output == "End\\n")
    }

    @Test("Complex real-world JSON string")
    func complexRealWorld() {
        let input = "{\"key\": \"value\",\n\t\"nested\": {\"path\": \"C:\\\\Users\\\\test\"}}"
        let output = escaper.escape(input)
        #expect(output.contains("\\\""))
        #expect(output.contains("\\n"))
        #expect(output.contains("\\t"))
        #expect(output.contains("\\\\"))
    }
}
