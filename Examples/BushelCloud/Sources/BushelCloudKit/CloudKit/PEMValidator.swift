//
//  PEMValidator.swift
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

import Foundation

/// Validates PEM format for CloudKit Server-to-Server private keys
internal enum PEMValidator {
  /// Validates a PEM string has proper structure and encoding
  ///
  /// **Checks performed:**
  /// 1. Contains BEGIN PRIVATE KEY header
  /// 2. Contains END PRIVATE KEY footer
  /// 3. Has content between headers
  /// 4. Content is valid base64
  ///
  /// **Why validate?**
  /// - Provides clear error messages before attempting CloudKit operations
  /// - Catches common copy/paste errors (truncation, missing markers)
  /// - Prevents cryptic errors from MistKit's ServerToServerAuthManager
  ///
  /// - Parameter pemString: The PEM-formatted private key string
  /// - Throws: BushelCloudKitError.invalidPEMFormat with specific reason and recovery suggestion
  internal static func validate(_ pemString: String) throws {
    let trimmed = pemString.trimmingCharacters(in: .whitespacesAndNewlines)

    // Check for BEGIN header
    guard trimmed.contains("-----BEGIN") && trimmed.contains("PRIVATE KEY-----") else {
      throw BushelCloudKitError.invalidPEMFormat(
        reason: "Missing '-----BEGIN PRIVATE KEY-----' header",
        suggestion: """
          Ensure you copied the entire PEM file including the header line. \
          Re-download from CloudKit Dashboard if needed.
          """
      )
    }

    // Check for END footer
    guard trimmed.contains("-----END") && trimmed.contains("PRIVATE KEY-----") else {
      throw BushelCloudKitError.invalidPEMFormat(
        reason: "Missing '-----END PRIVATE KEY-----' footer",
        suggestion: """
          The PEM file may have been truncated during copy/paste. \
          Ensure you copied the entire file including the footer line.
          """
      )
    }

    // Extract content between headers
    let lines = trimmed.components(separatedBy: .newlines)
    let contentLines = lines.filter { line in
      !line.contains("BEGIN") && !line.contains("END") && !line.isEmpty
    }

    guard !contentLines.isEmpty else {
      throw BushelCloudKitError.invalidPEMFormat(
        reason: "PEM file contains no key data between headers",
        suggestion: "The key file may be corrupted or empty. Re-download from CloudKit Dashboard."
      )
    }

    // Validate base64 encoding
    let base64Content = contentLines.joined()
    guard Data(base64Encoded: base64Content) != nil else {
      throw BushelCloudKitError.invalidPEMFormat(
        reason: "PEM content is not valid base64 encoding",
        suggestion: """
          The key file may be corrupted. \
          Ensure you used a text editor (not binary editor) and the file is UTF-8 encoded.
          """
      )
    }
  }
}
