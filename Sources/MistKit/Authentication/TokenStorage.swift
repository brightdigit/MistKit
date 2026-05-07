//
//  TokenStorage.swift
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

/// Protocol for persisting and retrieving authenticators.
public protocol TokenStorage: Sendable {
  /// Stores an authenticator with an optional identifier.
  /// - Parameters:
  ///   - authenticator: The authenticator to persist.
  ///   - identifier: Optional identifier for storing multiple authenticators.
  /// - Throws: `TokenStorageError` if storage fails.
  func store(
    _ authenticator: any Authenticator,
    identifier: String?
  ) async throws(TokenStorageError)

  /// Retrieves a stored authenticator.
  /// - Parameter identifier: Optional identifier for specific credentials.
  /// - Returns: The stored authenticator, or `nil` if not found.
  /// - Throws: `TokenStorageError` if retrieval fails.
  func retrieve(identifier: String?) async throws(TokenStorageError) -> (any Authenticator)?

  /// Removes a stored authenticator.
  /// - Parameter identifier: Optional identifier for specific credentials.
  /// - Throws: `TokenStorageError` if removal fails.
  func remove(identifier: String?) async throws(TokenStorageError)

  /// Lists all stored authenticator identifiers.
  func listIdentifiers() async throws(TokenStorageError) -> [String]
}
