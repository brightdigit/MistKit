//
//  TableEscaperTests.swift
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

@Suite("TableEscaper Tests - Single-Line Conversion")
struct TableEscaperTests {
    let escaper = TableEscaper()

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

    // MARK: - Newline Conversion Tests

    @Test("Newline is converted to space")
    func newlineToSpace() {
        let input = "Line 1\nLine 2"
        let output = escaper.escape(input)
        #expect(output == "Line 1 Line 2")
    }

    @Test("Multiple newlines are converted to spaces")
    func multipleNewlinesToSpaces() {
        let input = "A\nB\nC"
        let output = escaper.escape(input)
        #expect(output == "A B C")
    }

    @Test("Consecutive newlines become consecutive spaces")
    func consecutiveNewlines() {
        let input = "Text\n\nMore"
        let output = escaper.escape(input)
        #expect(output == "Text  More")
    }

    @Test("String starting with newline")
    func startingWithNewline() {
        let input = "\nText"
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    @Test("String ending with newline")
    func endingWithNewline() {
        let input = "Text\n"
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    // MARK: - Carriage Return Conversion Tests

    @Test("Carriage return is converted to space")
    func carriageReturnToSpace() {
        let input = "Before\rAfter"
        let output = escaper.escape(input)
        #expect(output == "Before After")
    }

    @Test("CRLF is converted to spaces")
    func crlfToSpaces() {
        let input = "Windows\r\nLine"
        let output = escaper.escape(input)
        #expect(output == "Windows  Line")
    }

    @Test("Multiple carriage returns")
    func multipleCarriageReturns() {
        let input = "A\rB\rC"
        let output = escaper.escape(input)
        #expect(output == "A B C")
    }

    // MARK: - Tab Conversion Tests

    @Test("Tab is converted to space")
    func tabToSpace() {
        let input = "Column1\tColumn2"
        let output = escaper.escape(input)
        #expect(output == "Column1 Column2")
    }

    @Test("Multiple tabs are converted to spaces")
    func multipleTabs() {
        let input = "A\tB\tC"
        let output = escaper.escape(input)
        #expect(output == "A B C")
    }

    @Test("Consecutive tabs")
    func consecutiveTabs() {
        let input = "Text\t\tMore"
        let output = escaper.escape(input)
        #expect(output == "Text  More")
    }

    // MARK: - Whitespace Trimming Tests

    @Test("Leading whitespace is trimmed")
    func leadingWhitespaceTrimmed() {
        let input = "   Text"
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    @Test("Trailing whitespace is trimmed")
    func trailingWhitespaceTrimmed() {
        let input = "Text   "
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    @Test("Leading and trailing whitespace trimmed")
    func bothSidesWhitespaceTrimmed() {
        let input = "  Text  "
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    @Test("String with only whitespace becomes empty")
    func onlyWhitespace() {
        let input = "   "
        let output = escaper.escape(input)
        #expect(output == "")
    }

    @Test("Newline-only string becomes empty")
    func onlyNewlines() {
        let input = "\n\n\n"
        let output = escaper.escape(input)
        #expect(output == "")
    }

    // MARK: - Combination Tests

    @Test("Newlines, tabs, and spaces together")
    func allWhitespaceTypes() {
        let input = "A\nB\tC D"
        let output = escaper.escape(input)
        #expect(output == "A B C D")
    }

    @Test("Complex multi-line with tabs")
    func complexMultiLine() {
        let input = "Line 1\n\tIndented\nLine 3"
        let output = escaper.escape(input)
        #expect(output == "Line 1  Indented Line 3")
    }

    @Test("Mixed whitespace with trimming")
    func mixedWithTrimming() {
        let input = "  \n Text \t  "
        let output = escaper.escape(input)
        #expect(output == "Text")
    }

    @Test("Internal spaces preserved")
    func internalSpacesPreserved() {
        let input = "Word1 Word2  Word3"
        let output = escaper.escape(input)
        #expect(output == "Word1 Word2  Word3")
    }

    // MARK: - Unicode and Emoji Tests

    @Test("Emoji preserved")
    func emojiPreserved() {
        let input = "Hello 👋 World"
        let output = escaper.escape(input)
        #expect(output == "Hello 👋 World")
    }

    @Test("Emoji with newline")
    func emojiWithNewline() {
        let input = "Test 👍\nMore"
        let output = escaper.escape(input)
        #expect(output == "Test 👍 More")
    }

    @Test("Unicode characters preserved")
    func unicodePreserved() {
        let input = "Café résumé"
        let output = escaper.escape(input)
        #expect(output == "Café résumé")
    }

    // MARK: - Edge Cases

    @Test("Very long multi-line string")
    func longMultiLine() {
        let input = String(repeating: "line\n", count: 100)
        let output = escaper.escape(input)
        #expect(!output.contains("\n"))
        #expect(output.contains("line"))
    }

    @Test("String with all whitespace types mixed")
    func allWhitespaceTypesMixed() {
        let input = " \n\t\r "
        let output = escaper.escape(input)
        #expect(output == "")
    }

    @Test("Preserves special characters except whitespace")
    func preservesSpecialChars() {
        let input = "Test,with;special:chars"
        let output = escaper.escape(input)
        #expect(output == "Test,with;special:chars")
    }
}
