//
//  TokenRefreshManager.swift
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

public import Foundation

/// Protocol for managing token refresh operations
public protocol TokenRefreshManager: Sendable {
  /// Refreshes the current token if needed
  /// - Returns: Updated TokenCredentials or nil if no refresh needed
  /// - Throws: TokenManagerError if refresh fails
  func refreshTokenIfNeeded() async throws(TokenManagerError) -> TokenCredentials?

  /// Forces a token refresh regardless of expiry
  /// - Returns: Updated TokenCredentials
  /// - Throws: TokenManagerError if refresh fails
  func forceRefreshToken() async throws(TokenManagerError) -> TokenCredentials

  /// Checks if token refresh is needed
  /// - Returns: True if refresh is needed
  func isRefreshNeeded() async -> Bool
}
