//
//  InternalErrorReason.swift
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

/// Specific reasons for internal errors
public enum InternalErrorReason: Sendable {
  case noCredentialsAvailable
  case failedCredentialRetrievalAfterUpgrade
  case failedCredentialRetrievalAfterDowngrade
  case serverToServerRequiresSpecificManager
  case serverToServerRequiresPlatformSupport

  public var description: String {
    switch self {
    case .noCredentialsAvailable:
      return "No credentials available"
    case .failedCredentialRetrievalAfterUpgrade:
      return "Failed to get credentials after upgrade"
    case .failedCredentialRetrievalAfterDowngrade:
      return "Failed to get credentials after downgrade"
    case .serverToServerRequiresSpecificManager:
      return "Server-to-server credentials require ServerToServerAuthManager"
    case .serverToServerRequiresPlatformSupport:
      return
        "Server-to-server authentication requires macOS 11.0+, iOS 14.0+, tvOS 14.0+, or watchOS 7.0+"
    }
  }
}
