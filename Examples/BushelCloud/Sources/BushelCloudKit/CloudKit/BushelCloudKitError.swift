//
//  BushelCloudKitError.swift
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

public import Foundation

/// Errors that can occur during BushelCloudKitService operations
public enum BushelCloudKitError: LocalizedError {
  case privateKeyFileNotFound(path: String)
  case privateKeyFileReadFailed(path: String, error: any Error)
  case invalidPEMFormat(reason: String, suggestion: String)
  case invalidMetadataRecord(recordName: String)

  public var errorDescription: String? {
    switch self {
    case .privateKeyFileNotFound(let path):
      return "Private key file not found at path: \(path)"
    case .privateKeyFileReadFailed(let path, let error):
      return "Failed to read private key file at \(path): \(error.localizedDescription)"
    case .invalidPEMFormat(let reason, let suggestion):
      return """
        Invalid PEM format: \(reason)

        Suggestion: \(suggestion)

        Expected format:
        -----BEGIN PRIVATE KEY-----
        [base64 encoded key data]
        -----END PRIVATE KEY-----
        """
    case .invalidMetadataRecord(let recordName):
      return "Invalid DataSourceMetadata record: \(recordName) (missing required fields)"
    }
  }

  public var recoverySuggestion: String? {
    switch self {
    case .invalidPEMFormat(_, let suggestion):
      return suggestion
    case .privateKeyFileNotFound(let path):
      return """
        Ensure the file exists at \(path) or set CLOUDKIT_PRIVATE_KEY_PATH environment variable.
        To generate a new key, visit: https://icloud.developer.apple.com/dashboard/
        """
    default:
      return nil
    }
  }
}
