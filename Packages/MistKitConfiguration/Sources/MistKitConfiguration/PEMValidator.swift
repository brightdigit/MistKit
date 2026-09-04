//
//  PEMValidator.swift
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

/// Validates the structure and encoding of a PEM-encoded private key.
///
/// Catches the common copy/paste failures — truncation, a missing marker, a binary-mangled
/// body — before the key ever reaches MistKit's signing path.
public enum PEMValidator {
  /// Validates that a PEM string is well formed.
  ///
  /// Checks, in order: a `BEGIN … PRIVATE KEY` header, an `END … PRIVATE KEY` footer,
  /// non-empty content between them, and that the content is valid base64.
  ///
  /// - Parameter pemString: The PEM-formatted private key.
  /// - Throws: ``PEMValidationFailure`` describing the first problem found.
  public static func validate(_ pemString: String) throws(PEMValidationFailure) {
    let trimmed = pemString.trimmingCharacters(in: .whitespacesAndNewlines)

    guard trimmed.contains("-----BEGIN"), trimmed.contains("PRIVATE KEY-----") else {
      throw .missingHeader
    }
    guard trimmed.contains("-----END"), trimmed.contains("PRIVATE KEY-----") else {
      throw .missingFooter
    }

    let contentLines = trimmed.components(separatedBy: .newlines).filter { line in
      !line.contains("BEGIN") && !line.contains("END") && !line.isEmpty
    }
    guard !contentLines.isEmpty else {
      throw .emptyContent
    }
    guard Data(base64Encoded: contentLines.joined()) != nil else {
      throw .invalidBase64
    }
  }
}
