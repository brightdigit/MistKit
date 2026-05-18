//
//  KeyIDValidator.swift
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

internal import Foundation

/// Validates CloudKit Server-to-Server Key ID format
internal enum KeyIDValidator {
  private static let allowedCharacters = CharacterSet(
    charactersIn: "0123456789abcdefABCDEF"
  )

  /// Validates that a key ID has the expected CloudKit S2S format.
  ///
  /// CloudKit Server-to-Server keys are SHA-256 fingerprints of the public key:
  /// 64 lowercase hex characters. We accept upper- or lower-case to be lenient
  /// about copy/paste from the dashboard.
  ///
  /// - Parameter keyID: The key ID to validate.
  /// - Throws: `BushelCloudKitError.invalidKeyID` with a specific reason and suggestion.
  internal static func validate(_ keyID: String) throws {
    let trimmed = keyID.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmed.isEmpty else {
      throw BushelCloudKitError.invalidKeyID(
        reason: "Key ID is empty",
        suggestion: """
          Set CLOUDKIT_KEY_ID to the Server-to-Server key ID from the CloudKit \
          Dashboard (a 64-character hex string).
          """
      )
    }

    guard trimmed == keyID else {
      throw BushelCloudKitError.invalidKeyID(
        reason: "Key ID has surrounding whitespace",
        suggestion: """
          Trim leading/trailing whitespace from CLOUDKIT_KEY_ID. Common cause: \
          accidental newline or space when copying from the dashboard.
          """
      )
    }

    guard trimmed.count == 64 else {
      throw BushelCloudKitError.invalidKeyID(
        reason: "Key ID must be 64 characters (got \(trimmed.count))",
        suggestion: """
          CloudKit Server-to-Server keys are 64-character hex strings. \
          Re-copy the full key ID from the CloudKit Dashboard.
          """
      )
    }

    guard trimmed.unicodeScalars.allSatisfy(allowedCharacters.contains) else {
      throw BushelCloudKitError.invalidKeyID(
        reason: "Key ID contains non-hex characters",
        suggestion: """
          The key ID should be hex (0-9, a-f). Verify you copied the Key ID — \
          not the key name or container ID — from the CloudKit Dashboard.
          """
      )
    }
  }
}
