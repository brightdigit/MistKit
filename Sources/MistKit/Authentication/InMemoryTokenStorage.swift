//
//  InMemoryTokenStorage.swift
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

public import Foundation

/// Simple in-memory implementation of TokenStorage for development and testing
/// This implementation does not persist data across application restarts
public final class InMemoryTokenStorage: TokenStorage, Sendable {
  private let storage = Storage()

  /// Thread-safe storage using actor
  private actor Storage {
    private var credentials: [String: TokenCredentials] = [:]

    func store(_ tokenCredentials: TokenCredentials, identifier: String?) {
      let key = identifier ?? "default"
      credentials[key] = tokenCredentials
    }

    func retrieve(identifier: String?) -> TokenCredentials? {
      let key = identifier ?? "default"
      return credentials[key]
    }

    func remove(identifier: String?) {
      let key = identifier ?? "default"
      credentials.removeValue(forKey: key)
    }

    func listIdentifiers() -> [String] {
      Array(credentials.keys)
    }

    func clear() {
      credentials.removeAll()
    }
  }

  /// Creates a new in-memory token storage
  public init() {}

  // MARK: - TokenStorage Protocol

  public func store(_ credentials: TokenCredentials, identifier: String?) async throws {
    await storage.store(credentials, identifier: identifier)
  }

  public func retrieve(identifier: String?) async throws -> TokenCredentials? {
    await storage.retrieve(identifier: identifier)
  }

  public func remove(identifier: String?) async throws {
    await storage.remove(identifier: identifier)
  }

  public func listIdentifiers() async throws -> [String] {
    await storage.listIdentifiers()
  }

  /// Clears all stored credentials (useful for testing and development)
  public func clear() async {
    await storage.clear()
  }

  /// Returns the number of stored credentials
  public var count: Int {
    get async {
      let identifiers = await storage.listIdentifiers()
      return identifiers.count
    }
  }

  /// Returns true if the storage is empty
  public var isEmpty: Bool {
    get async {
      let identifiers = await storage.listIdentifiers()
      return identifiers.isEmpty
    }
  }
}

// MARK: - Convenience Methods

extension InMemoryTokenStorage {
  /// Stores credentials with automatic identifier based on authentication method
  /// - Parameter credentials: The credentials to store
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
  public func retrieve(byMethodType methodType: String) async throws -> TokenCredentials? {
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
