//
//  CredentialValidationError.swift
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

public import Foundation

/// A malformed CloudKit server-to-server credential, caught before it reaches
/// MistKit.
///
/// Validating locally turns an opaque signing failure into a message naming the
/// offending value and how to fix it.
public enum CredentialValidationError: LocalizedError, Equatable {
  /// PEM text that is not a well-formed private key.
  case invalidPEMFormat(reason: String, suggestion: String)
  /// A key ID that is not a 64-character hexadecimal string.
  case invalidKeyID(reason: String, suggestion: String)

  public var errorDescription: String? {
    switch self {
    case .invalidPEMFormat(let reason, let suggestion):
      return """
        Invalid PEM format: \(reason)

        Suggestion: \(suggestion)

        Expected format:
        -----BEGIN PRIVATE KEY-----
        [base64 encoded key data]
        -----END PRIVATE KEY-----
        """
    case .invalidKeyID(let reason, let suggestion):
      return """
        Invalid CloudKit Server-to-Server Key ID: \(reason)

        Suggestion: \(suggestion)
        """
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidPEMFormat(_, let suggestion), .invalidKeyID(_, let suggestion):
      return suggestion
    }
  }
}
