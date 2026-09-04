//
//  PEMValidatorTests.swift
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

internal import Foundation
internal import Testing

@testable import MistKitConfiguration

@Suite("PEMValidator")
internal struct PEMValidatorTests {
  @Test("Accepts a well-formed PEM")
  internal func acceptsValidPEM() throws {
    try PEMValidator.validate(TestFixtures.validPEM)
  }

  @Test("Rejects a missing header")
  internal func rejectsMissingHeader() {
    let pem = "\(Data(repeating: 0x41, count: 48).base64EncodedString())\n-----END PRIVATE KEY-----"
    #expect(throws: PEMValidationFailure.missingHeader) { try PEMValidator.validate(pem) }
  }

  @Test("Rejects a truncated key with no footer")
  internal func rejectsMissingFooter() {
    let pem = "-----BEGIN PRIVATE KEY-----\nQUFB"
    #expect(throws: PEMValidationFailure.missingFooter) { try PEMValidator.validate(pem) }
  }

  @Test("Rejects headers enclosing no key data")
  internal func rejectsEmptyContent() {
    let pem = "-----BEGIN PRIVATE KEY-----\n-----END PRIVATE KEY-----"
    #expect(throws: PEMValidationFailure.emptyContent) { try PEMValidator.validate(pem) }
  }

  @Test("Rejects content that is not base64")
  internal func rejectsInvalidBase64() {
    let pem = "-----BEGIN PRIVATE KEY-----\n!!!not base64!!!\n-----END PRIVATE KEY-----"
    #expect(throws: PEMValidationFailure.invalidBase64) { try PEMValidator.validate(pem) }
  }
}
