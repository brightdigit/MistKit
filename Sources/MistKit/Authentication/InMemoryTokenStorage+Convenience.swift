//
//  InMemoryTokenStorage+Convenience.swift
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

// MARK: - Convenience Methods

extension InMemoryTokenStorage {
  /// Stores credentials with automatic identifier based on authentication method
  /// - Parameter credentials: The credentials to store
  /// - Throws: TokenStorageError if the storage operation fails
  public func store(_ credentials: TokenCredentials) async throws {
    let identifier: String

    switch credentials.method {
    case .apiToken(let token):
      identifier = "api-\(token.prefix(8))"
    case .webAuthToken(let apiToken, _):
      identifier = "web-\(apiToken.prefix(8))"
    case .serverToServer(let keyID, _):
      identifier = "s2s-\(keyID)"
    }

    try await store(credentials, identifier: identifier)
  }

  /// Retrieves credentials by authentication method type
  /// - Parameter methodType: The authentication method type to search for
  /// - Returns: First matching credentials or nil if not found
  /// - Throws: TokenStorageError if the retrieval operation fails
  public func retrieve(byMethodType methodType: String) async throws(TokenStorageError)
    -> TokenCredentials?
  {
    let identifiers = try await listIdentifiers()

    for identifier in identifiers {
      if let credentials = try await retrieve(identifier: identifier),
        credentials.methodType == methodType
      {
        return credentials
      }
    }

    return nil
  }

  /// Lists all credentials grouped by method type
  /// - Returns: Dictionary mapping method types to arrays of credentials
  public func credentialsByMethodType() async throws -> [String: [TokenCredentials]] {
    var result: [String: [TokenCredentials]] = [:]
    let identifiers = try await listIdentifiers()

    for identifier in identifiers {
      if let credentials = try await retrieve(identifier: identifier) {
        let methodType = credentials.methodType
        result[methodType, default: []].append(credentials)
      }
    }

    return result
  }
}
