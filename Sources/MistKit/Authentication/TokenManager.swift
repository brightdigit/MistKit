//
//  TokenManager.swift
//  PackageDSLKit
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

#if canImport(Foundation)
import Foundation
#endif

/// Protocol for managing authentication tokens and credentials for CloudKit Web Services
public protocol TokenManager: Sendable {
  /// Validates the current authentication credentials
  /// - Returns: True if credentials are valid and usable
  /// - Throws: TokenManagerError if validation fails
  func validateCredentials() async throws -> Bool

  /// Retrieves the current token credentials
  /// - Returns: Current TokenCredentials or nil if none available
  /// - Throws: TokenManagerError if retrieval fails
  func getCurrentCredentials() async throws -> TokenCredentials?

  /// Checks if credentials are currently available
  var hasCredentials: Bool { get async }
}
