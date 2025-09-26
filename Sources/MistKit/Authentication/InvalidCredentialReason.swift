//
//  InvalidCredentialReason.swift
//  MistKit
//
//  Created by Leo Dion.
//  Copyright © 2025 BrightDigit.
//
//  Permission is hereby granted, free of charge, to any person
//  obtaining a copy of this software and associated documentation
//  files (the “Software”), to deal in the Software without
//  restriction, including without limitation the rights to use,
//  copy, modify, merge, publish, distribute, sublicense, and/or
//  sell copies of the Software, and to permit persons to whom the
//  Software is furnished to do so, subject to the following
//  conditions:
//
//  The above copyright notice and this permission notice shall be
//  included in all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND,
//  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
//  OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
//  NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
//  HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
//  WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//  FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
//  OTHER DEALINGS IN THE SOFTWARE.
//

internal import Foundation

/// Specific reasons for invalid credentials
public enum InvalidCredentialReason: Sendable {
  case apiTokenEmpty
  case apiTokenInvalidFormat
  case webAuthTokenEmpty
  case webAuthTokenTooShort
  case keyIdEmpty
  case keyIdTooShort
  case keyIdInvalidFormat
  case noCredentialsAvailable
  case invalidPEMFormat(any Error)
  case privateKeyParseFailed(any Error)
  case privateKeyInvalidOrCorrupted(any Error)
  case authenticationModeMismatch
  case serverToServerOnlySupportsPublicDatabase(String)

  public var description: String {
    switch self {
    case .apiTokenEmpty:
      return "API token is empty"
    case .apiTokenInvalidFormat:
      return "API token format is invalid (expected 64-character hex string)"
    case .webAuthTokenEmpty:
      return "Web auth token is empty"
    case .webAuthTokenTooShort:
      return "Web auth token appears to be too short"
    case .keyIdEmpty:
      return "Key ID is empty"
    case .keyIdTooShort:
      return "Key ID appears to be too short (minimum 8 characters)"
    case .keyIdInvalidFormat:
      return "Key ID format is invalid (expected 64-character hex string)"
    case .noCredentialsAvailable:
      return "No credentials available"
    case .invalidPEMFormat(let error):
      return "Invalid PEM format for private key: \(error.localizedDescription)"
    case .privateKeyParseFailed(let error):
      return "Failed to parse private key from PEM string: \(error.localizedDescription)"
    case .privateKeyInvalidOrCorrupted(let error):
      return "Private key is invalid or corrupted: \(error.localizedDescription)"
    case .authenticationModeMismatch:
      return "Cannot update web auth token when not in web authentication mode"
    case .serverToServerOnlySupportsPublicDatabase(let currentDatabase):
      return """
        Server-to-server authentication only supports the public database. \
        Current database: \(currentDatabase). \
        Use MistKitConfiguration.serverToServer() for proper configuration.
        """
    }
  }
}
