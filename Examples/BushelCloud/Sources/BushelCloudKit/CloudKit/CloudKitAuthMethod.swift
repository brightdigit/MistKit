//
//  CloudKitAuthMethod.swift
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

/// Authentication method for CloudKit Server-to-Server
///
/// Provides type-safe authentication credential handling with two patterns:
/// - `.pemString`: For CI/CD environments (GitHub Actions secrets)
/// - `.pemFile`: For local development (file on disk)
public enum CloudKitAuthMethod: Sendable {
  /// PEM content provided as string (CI/CD pattern)
  ///
  /// **Usage**: Pass PEM content from environment variables or secrets
  /// ```swift
  /// let method = .pemString(pemContentFromEnvironment)
  /// ```
  case pemString(String)

  /// PEM content loaded from file path (local development pattern)
  ///
  /// **Usage**: Pass path to .pem file on disk
  /// ```swift
  /// let method = .pemFile(path: "~/.cloudkit/bushel-private-key.pem")
  /// ```
  case pemFile(path: String)
}
