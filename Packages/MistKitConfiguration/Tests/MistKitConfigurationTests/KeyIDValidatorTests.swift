//
//  KeyIDValidatorTests.swift
//  MistKitConfiguration
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

@testable import MistKitConfiguration

@Suite("KeyIDValidator")
internal struct KeyIDValidatorTests {
  @Test("Accepts a 64-character hex key ID in either case")
  internal func acceptsValidKeyID() throws {
    try KeyIDValidator.validate(TestFixtures.validKeyID)
    try KeyIDValidator.validate(TestFixtures.validKeyID.uppercased())
  }

  @Test("Rejects an empty or whitespace-only key ID")
  internal func rejectsEmpty() {
    #expect(throws: KeyIDValidationFailure.empty) { try KeyIDValidator.validate("") }
    #expect(throws: KeyIDValidationFailure.empty) { try KeyIDValidator.validate("   ") }
  }

  @Test("Rejects surrounding whitespace, the classic copy/paste newline")
  internal func rejectsSurroundingWhitespace() {
    #expect(throws: KeyIDValidationFailure.surroundingWhitespace) {
      try KeyIDValidator.validate(" \(TestFixtures.validKeyID)\n")
    }
  }

  @Test("Reports the actual length when it is wrong")
  internal func reportsIncorrectLength() {
    #expect(throws: KeyIDValidationFailure.incorrectLength(actual: 3)) {
      try KeyIDValidator.validate("abc")
    }
    #expect(throws: KeyIDValidationFailure.incorrectLength(actual: 65)) {
      try KeyIDValidator.validate(TestFixtures.validKeyID + "a")
    }
  }

  @Test("Rejects non-hex characters")
  internal func rejectsNonHex() {
    let sameLengthNonHex = String(repeating: "z", count: KeyIDValidator.expectedLength)
    #expect(throws: KeyIDValidationFailure.nonHexCharacters) {
      try KeyIDValidator.validate(sameLengthNonHex)
    }
  }

  @Test("Expected length is CloudKit's 64-character fingerprint")
  internal func expectedLength() {
    #expect(KeyIDValidator.expectedLength == 64)
  }
}
