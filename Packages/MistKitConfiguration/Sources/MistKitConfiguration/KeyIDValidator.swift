//
//  KeyIDValidator.swift
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

/// Validates the format of a CloudKit Server-to-Server key ID.
///
/// CloudKit server-to-server keys are SHA-256 fingerprints of the public key: 64 hex
/// characters. Checking locally turns an opaque signing failure at request time into a
/// precise, switchable ``KeyIDValidationFailure`` at configuration time.
public enum KeyIDValidator {
  /// The exact number of characters a CloudKit server-to-server key ID has.
  public static let expectedLength = 64

  private static let hexDigits = Set("0123456789abcdefABCDEF")

  /// Validates that a key ID has the expected CloudKit server-to-server format.
  ///
  /// Upper- and lower-case hex are both accepted, to be lenient about a copy from the
  /// CloudKit Dashboard.
  ///
  /// - Parameter keyID: The key ID to validate.
  /// - Throws: ``KeyIDValidationFailure`` describing the first problem found.
  public static func validate(_ keyID: String) throws(KeyIDValidationFailure) {
    let trimmed = keyID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
      throw .empty
    }
    guard trimmed == keyID else {
      throw .surroundingWhitespace
    }
    guard trimmed.count == expectedLength else {
      throw .incorrectLength(actual: trimmed.count)
    }
    guard trimmed.allSatisfy(hexDigits.contains) else {
      throw .nonHexCharacters
    }
  }
}
