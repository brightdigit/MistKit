//
//  TokenManager.swift
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

/// Protocol for managing authentication tokens and credentials for CloudKit Web Services.
///
/// A `TokenManager` is the lifecycle owner of credentials (loading, validating,
/// rotating, persisting). It vends an `Authenticator` to whomever needs to apply
/// those credentials to an outgoing request.
public protocol TokenManager: Sendable {
  /// Checks if credentials are currently available.
  var hasCredentials: Bool { get async }

  /// Validates the current authentication credentials.
  /// - Returns: True if credentials are valid and usable.
  /// - Throws: `TokenManagerError` if validation fails.
  func validateCredentials() async throws(TokenManagerError) -> Bool

  /// Returns the authenticator that should be used for the next request,
  /// or `nil` if no credentials are available.
  func currentAuthenticator() async throws(TokenManagerError) -> (any Authenticator)?
}
