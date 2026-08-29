//
//  KeyIDValidatorTests.swift
//  BushelCloud
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

internal import Testing

@testable import BushelCloudKit

@Suite("Key ID Validation Tests")
internal struct KeyIDValidatorTests {
  // A representative 64-character hex Key ID (SHA-256 fingerprint length).
  private static let validLowercase =
    "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

  @Test("Valid 64-char lowercase hex passes validation")
  internal func testValidLowercase() {
    #expect(throws: Never.self) {
      try KeyIDValidator.validate(Self.validLowercase)
    }
  }

  @Test("Uppercase and mixed-case hex passes validation")
  internal func testCaseInsensitiveHex() {
    let uppercase = "ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789"
    let mixedCase = "AbCdEf0123456789abcdef0123456789ABCDEF0123456789aBcDeF0123456789"

    #expect(throws: Never.self) {
      try KeyIDValidator.validate(uppercase)
    }
    #expect(throws: Never.self) {
      try KeyIDValidator.validate(mixedCase)
    }
  }

  @Test("Empty string throws error")
  internal func testEmpty() {
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate("")
    }
  }

  @Test("Whitespace-only string throws error")
  internal func testWhitespaceOnly() {
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate("   \n  ")
    }
  }

  @Test("Surrounding whitespace on an otherwise-valid key throws error")
  internal func testSurroundingWhitespace() {
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate(" \(Self.validLowercase)\n")
    }
  }

  @Test("Too-short key throws error")
  internal func testTooShort() {
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate("0123456789abcdef")
    }
  }

  @Test("Too-long key throws error")
  internal func testTooLong() {
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate(Self.validLowercase + "00")
    }
  }

  @Test("Non-hex characters throw error")
  internal func testNonHexCharacters() {
    // 64 characters, but contains a non-hex letter ('g') and a dash.
    let withLetter = "g123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"
    let withDash = "-123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"

    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate(withLetter)
    }
    #expect(throws: BushelCloudKitError.self) {
      try KeyIDValidator.validate(withDash)
    }
  }

  @Test("Error messages are helpful")
  internal func testErrorMessages() {
    do {
      try KeyIDValidator.validate("invalid")
      Issue.record("Should have thrown error")
    } catch let error as BushelCloudKitError {
      let description = error.errorDescription ?? ""
      #expect(description.contains("Invalid CloudKit Server-to-Server Key ID"))
      #expect(error.recoverySuggestion != nil)
    } catch {
      Issue.record("Wrong error type: \(error)")
    }
  }
}
