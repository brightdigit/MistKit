//
//  CSVEscaperTests.swift
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

@Suite("CSVEscaper Tests - RFC 4180 Compliance")
struct CSVEscaperTests {
    let escaper = CSVEscaper()

    // MARK: - Plain String Tests

    @Test("Plain string without special characters needs no escaping")
    func plainStringNoEscaping() {
        let input = "Hello World"
        let output = escaper.escape(input)
        #expect(output == "Hello World")
    }

    @Test("Simple alphanumeric string needs no escaping")
    func alphanumericNoEscaping() {
        let input = "Test123"
        let output = escaper.escape(input)
        #expect(output == "Test123")
    }

    @Test("String with spaces needs no escaping")
    func stringWithSpacesNoEscaping() {
        let input = "This is a test"
        let output = escaper.escape(input)
        #expect(output == "This is a test")
    }

    @Test("Empty string needs no escaping")
    func emptyStringNoEscaping() {
        let input = ""
        let output = escaper.escape(input)
        #expect(output == "")
    }

    // MARK: - Comma Escaping Tests

    @Test("String with comma is escaped and quoted")
    func stringWithCommaIsEscaped() {
        let input = "value1,value2"
        let output = escaper.escape(input)
        #expect(output == "\"value1,value2\"")
    }

    @Test("String starting with comma is escaped")
    func stringStartingWithComma() {
        let input = ",leading"
        let output = escaper.escape(input)
        #expect(output == "\",leading\"")
    }

    @Test("String ending with comma is escaped")
    func stringEndingWithComma() {
        let input = "trailing,"
        let output = escaper.escape(input)
        #expect(output == "\"trailing,\"")
    }

    @Test("String with multiple commas is escaped")
    func stringWithMultipleCommas() {
        let input = "a,b,c,d"
        let output = escaper.escape(input)
        #expect(output == "\"a,b,c,d\"")
    }

    // MARK: - Quote Escaping Tests (RFC 4180)

    @Test("String with quote is escaped by doubling")
    func stringWithQuoteIsDoubled() {
        let input = "She said \"Hello\""
        let output = escaper.escape(input)
        #expect(output == "\"She said \"\"Hello\"\"\"")
    }

    @Test("String with single quote character")
    func singleQuoteCharacter() {
        let input = "\"quote\""
        let output = escaper.escape(input)
        #expect(output == "\"\"\"quote\"\"\"")
    }

    @Test("String with multiple quotes")
    func multipleQuotes() {
        let input = "\"Hello\" \"World\""
        let output = escaper.escape(input)
        #expect(output == "\"\"\"Hello\"\" \"\"World\"\"\"")
    }

    @Test("Empty quotes")
    func emptyQuotes() {
        let input = "\"\""
        let output = escaper.escape(input)
        #expect(output == "\"\"\"\"\"\"")
    }

    // MARK: - Newline Escaping Tests

    @Test("String with newline is escaped and quoted")
    func stringWithNewline() {
        let input = "Line 1\nLine 2"
        let output = escaper.escape(input)
        #expect(output == "\"Line 1\nLine 2\"")
    }

    @Test("String with carriage return is escaped")
    func stringWithCarriageReturn() {
        let input = "Before\rAfter"
        let output = escaper.escape(input)
        #expect(output == "\"Before\rAfter\"")
    }

    @Test("String with CRLF is escaped")
    func stringWithCRLF() {
        let input = "Windows\r\nLine"
        let output = escaper.escape(input)
        #expect(output == "\"Windows\r\nLine\"")
    }

    @Test("String with only newline")
    func onlyNewline() {
        let input = "\n"
        let output = escaper.escape(input)
        #expect(output == "\"\n\"")
    }

    // MARK: - Tab Escaping Tests

    @Test("String with tab is escaped and quoted")
    func stringWithTab() {
        let input = "Column1\tColumn2"
        let output = escaper.escape(input)
        #expect(output == "\"Column1\tColumn2\"")
    }

    @Test("String with multiple tabs")
    func stringWithMultipleTabs() {
        let input = "A\tB\tC"
        let output = escaper.escape(input)
        #expect(output == "\"A\tB\tC\"")
    }

    // MARK: - Combination Tests

    @Test("String with comma and quote")
    func commaAndQuote() {
        let input = "Value, \"quoted\""
        let output = escaper.escape(input)
        #expect(output == "\"Value, \"\"quoted\"\"\"")
    }

    @Test("String with all special characters")
    func allSpecialCharacters() {
        let input = "Test,\"value\"\nwith\ttab\rand more"
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
        #expect(output.contains("\"\"value\"\""))
    }

    @Test("Complex RFC 4180 example")
    func complexRFC4180() {
        let input = "1997,Ford,E350,\"Super, \"\"luxurious\"\" truck\""
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
    }

    // MARK: - Unicode and Emoji Tests

    @Test("String with emoji needs no escaping")
    func stringWithEmoji() {
        let input = "Hello 👋 World"
        let output = escaper.escape(input)
        #expect(output == "Hello 👋 World")
    }

    @Test("String with emoji and comma is escaped")
    func emojiWithComma() {
        let input = "Test,👍"
        let output = escaper.escape(input)
        #expect(output == "\"Test,👍\"")
    }

    @Test("String with unicode characters")
    func unicodeCharacters() {
        let input = "Café résumé"
        let output = escaper.escape(input)
        #expect(output == "Café résumé")
    }

    @Test("String with Japanese characters")
    func japaneseCharacters() {
        let input = "こんにちは"
        let output = escaper.escape(input)
        #expect(output == "こんにちは")
    }

    // MARK: - Edge Cases

    @Test("String with only spaces")
    func onlySpaces() {
        let input = "   "
        let output = escaper.escape(input)
        #expect(output == "   ")
    }

    @Test("Single character special")
    func singleCharacterComma() {
        let input = ","
        let output = escaper.escape(input)
        #expect(output == "\",\"")
    }

    @Test("Single character quote")
    func singleCharacterQuote() {
        let input = "\""
        let output = escaper.escape(input)
        #expect(output == "\"\"\"\"")
    }

    @Test("Long string with no special characters")
    func longPlainString() {
        let input = String(repeating: "a", count: 1000)
        let output = escaper.escape(input)
        #expect(output == input)
    }

    @Test("Long string with commas")
    func longStringWithCommas() {
        let input = String(repeating: "a,", count: 100)
        let output = escaper.escape(input)
        #expect(output.hasPrefix("\""))
        #expect(output.hasSuffix("\""))
        #expect(output.contains(","))
    }
}
