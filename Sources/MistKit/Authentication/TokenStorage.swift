//
//  TokenStorage.swift
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

/// Errors that can occur during token storage operations
public enum TokenStorageError: Error, LocalizedError, Sendable {
  /// Storage operation failed
  case storageFailed(reason: String)

  /// Credentials not found
  case notFound(identifier: String?)

  /// Access denied to storage
  case accessDenied

  /// Storage corrupted or invalid format
  case corruptedStorage

  /// A localized message describing what error occurred
  public var errorDescription: String? {
    switch self {
    case .storageFailed(let reason):
      return "Token storage failed: \(reason)"
    case .notFound(let identifier):
      if let identifier = identifier {
        return "Credentials not found for identifier: \(identifier)"
      } else {
        return "No credentials found"
      }
    case .accessDenied:
      return "Access denied to token storage"
    case .corruptedStorage:
      return "Token storage is corrupted or in invalid format"
    }
  }
}

/// Protocol for persisting and retrieving authentication tokens/keys
public protocol TokenStorage: Sendable {
  /// Stores token credentials with an optional identifier
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - identifier: Optional identifier for multiple credential storage
  /// - Throws: TokenStorageError if storage fails
  func store(_ credentials: TokenCredentials, identifier: String?) async throws(TokenStorageError)

  /// Retrieves stored token credentials
  /// - Parameter identifier: Optional identifier for specific credentials
  /// - Returns: Stored credentials or nil if not found
  /// - Throws: TokenStorageError if retrieval fails
  func retrieve(identifier: String?) async throws(TokenStorageError) -> TokenCredentials?

  /// Removes stored credentials
  /// - Parameter identifier: Optional identifier for specific credentials
  /// - Throws: TokenStorageError if removal fails
  func remove(identifier: String?) async throws(TokenStorageError)

  /// Lists all stored credential identifiers
  /// - Returns: Array of stored identifiers
  func listIdentifiers() async throws(TokenStorageError) -> [String]
}
