//
//  PEMValidatorTests.swift
//  BushelCloud
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
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

import Testing

@testable import BushelCloudKit

@Suite("PEM Validation Tests")
internal struct PEMValidatorTests {
  @Test("Valid PEM passes validation")
  internal func testValidPEM() throws {
    let validPEM = """
      -----BEGIN PRIVATE KEY-----
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg
      -----END PRIVATE KEY-----
      """

    #expect(throws: Never.self) {
      try PEMValidator.validate(validPEM)
    }
  }

  @Test("Missing header throws error")
  internal func testMissingHeader() {
    let invalidPEM = """
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg
      -----END PRIVATE KEY-----
      """

    #expect(throws: BushelCloudKitError.self) {
      try PEMValidator.validate(invalidPEM)
    }
  }

  @Test("Missing footer throws error")
  internal func testMissingFooter() {
    let invalidPEM = """
      -----BEGIN PRIVATE KEY-----
      MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQg
      """

    #expect(throws: BushelCloudKitError.self) {
      try PEMValidator.validate(invalidPEM)
    }
  }

  @Test("Empty content throws error")
  internal func testEmptyContent() {
    let invalidPEM = """
      -----BEGIN PRIVATE KEY-----
      -----END PRIVATE KEY-----
      """

    #expect(throws: BushelCloudKitError.self) {
      try PEMValidator.validate(invalidPEM)
    }
  }

  @Test("Invalid base64 throws error")
  internal func testInvalidBase64() {
    let invalidPEM = """
      -----BEGIN PRIVATE KEY-----
      not-valid-base64-content!!!
      -----END PRIVATE KEY-----
      """

    #expect(throws: BushelCloudKitError.self) {
      try PEMValidator.validate(invalidPEM)
    }
  }

  @Test("Error messages are helpful")
  internal func testErrorMessages() {
    let invalidPEM = "invalid"

    do {
      try PEMValidator.validate(invalidPEM)
      Issue.record("Should have thrown error")
    } catch let error as BushelCloudKitError {
      let description = error.errorDescription ?? ""
      #expect(description.contains("BEGIN PRIVATE KEY"))
      #expect(error.recoverySuggestion != nil)
    } catch {
      Issue.record("Wrong error type: \(error)")
    }
  }
}
