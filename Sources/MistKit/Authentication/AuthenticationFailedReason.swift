//
//  AuthenticationFailedReason.swift
//  MistKit
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

/// Specific reasons for authentication failure
public enum AuthenticationFailedReason: Sendable {
  /// Server rejected the authentication request
  case serverRejected(statusCode: Int, message: String?)

  /// Token generation failed
  case tokenGenerationFailed(any Error)

  /// Cryptographic signing failed
  case signingFailed(any Error)

  /// A human-readable description of the authentication failure reason
  public var description: String {
    switch self {
    case .serverRejected(let statusCode, let message):
      if let message {
        return "Server rejected authentication with HTTP \(statusCode): \(message)"
      }
      return "Server rejected authentication with HTTP \(statusCode)"
    case .tokenGenerationFailed(let error):
      return "Token generation failed: \(error.localizedDescription)"
    case .signingFailed(let error):
      return "Cryptographic signing failed: \(error.localizedDescription)"
    }
  }
}
