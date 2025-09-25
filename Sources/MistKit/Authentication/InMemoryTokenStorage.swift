//
//  InMemoryTokenStorage.swift
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

/// Simple in-memory implementation of TokenStorage for development and testing
/// This implementation does not persist data across application restarts
public final class InMemoryTokenStorage: TokenStorage, Sendable {
  /// Thread-safe storage using actor
  private actor Storage {
    private var credentials: [String: TokenCredentials] = [:]
    private var expirationTimes: [String: Date] = [:]

    func store(
      _ tokenCredentials: TokenCredentials, identifier: String?, expirationTime: Date? = nil
    ) {
      let key = identifier ?? "default"
      credentials[key] = tokenCredentials
      expirationTimes[key] = expirationTime
    }

    func retrieve(identifier: String?) -> TokenCredentials? {
      let key = identifier ?? "default"

      // Check if token has expired
      if let expirationTime = expirationTimes[key], expirationTime < Date() {
        // Token has expired, remove it
        credentials.removeValue(forKey: key)
        expirationTimes.removeValue(forKey: key)
        return nil
      }

      return credentials[key]
    }

    func remove(identifier: String?) {
      let key = identifier ?? "default"
      credentials.removeValue(forKey: key)
      expirationTimes.removeValue(forKey: key)
    }

    func listIdentifiers() -> [String] {
      // Return all stored identifiers, including expired ones
      Array(credentials.keys)
    }

    func clear() {
      credentials.removeAll()
      expirationTimes.removeAll()
    }

    func cleanupExpiredTokens() {
      let now = Date()
      let expiredKeys = expirationTimes.compactMap { key, expirationTime in
        expirationTime < now ? key : nil
      }

      for key in expiredKeys {
        credentials.removeValue(forKey: key)
        expirationTimes.removeValue(forKey: key)
      }
    }
  }

  private let storage = Storage()

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

  /// Creates a new in-memory token storage
  public init() {}

  // MARK: - TokenStorage Protocol

  public func store(_ credentials: TokenCredentials, identifier: String?) async throws {
    await storage.store(credentials, identifier: identifier, expirationTime: nil)
  }

  /// Stores credentials with expiration time
  /// - Parameters:
  ///   - credentials: The credentials to store
  ///   - identifier: Optional identifier for the credentials
  ///   - expirationTime: When the credentials expire
  public func store(_ credentials: TokenCredentials, identifier: String?, expirationTime: Date?)
    async throws
  {
    await storage.store(credentials, identifier: identifier, expirationTime: expirationTime)
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

  /// Cleans up expired tokens from storage
  public func cleanupExpiredTokens() async {
    await storage.cleanupExpiredTokens()
  }
}
