//
//  InMemoryTokenStorage.swift
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

public import Foundation

/// Simple in-memory implementation of `TokenStorage` for development and
/// testing. Does not persist data across application restarts.
public final class InMemoryTokenStorage: TokenStorage, Sendable {
  /// Routes decoding by `Authenticator.storageKey`.
  private static let factories: [String: @Sendable (Data) throws -> any Authenticator] = {
    var entries: [String: @Sendable (Data) throws -> any Authenticator] = [
      APITokenAuthenticator.storageKey: { try APITokenAuthenticator(decoding: $0) },
      WebAuthTokenAuthenticator.storageKey: { try WebAuthTokenAuthenticator(decoding: $0) },
    ]
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
      entries[ServerToServerAuthenticator.storageKey] = {
        try ServerToServerAuthenticator(decoding: $0)
      }
    }
    return entries
  }()

  private struct StoredEntry: Sendable {
    let storageKey: String
    let payload: Data
    let expirationTime: Date?
  }

  private actor Storage {
    private var entries: [String: StoredEntry] = [:]

    func store(_ entry: StoredEntry, identifier: String?) {
      entries[identifier ?? "default"] = entry
    }

    func retrieve(identifier: String?) -> StoredEntry? {
      let key = identifier ?? "default"
      if let expiration = entries[key]?.expirationTime, expiration <= Date() {
        entries.removeValue(forKey: key)
        return nil
      }
      return entries[key]
    }

    func remove(identifier: String?) {
      entries.removeValue(forKey: identifier ?? "default")
    }

    func listIdentifiers() -> [String] {
      Array(entries.keys)
    }

    func clear() {
      entries.removeAll()
    }

    func cleanupExpiredTokens() {
      let now = Date()
      entries = entries.filter { _, entry in
        guard let expiration = entry.expirationTime else {
          return true
        }
        return expiration > now
      }
    }
  }

  private let storage = Storage()

  /// Returns the number of stored credentials.
  public var count: Int {
    get async {
      await storage.listIdentifiers().count
    }
  }

  /// Returns true if the storage is empty.
  public var isEmpty: Bool {
    get async {
      await storage.listIdentifiers().isEmpty
    }
  }

  /// Creates a new in-memory token storage.
  public init() {}

  // MARK: - TokenStorage Protocol

  public func store(
    _ authenticator: any Authenticator,
    identifier: String?
  ) async throws(TokenStorageError) {
    try await store(authenticator, identifier: identifier, expirationTime: nil)
  }

  /// Stores an authenticator with an expiration time.
  public func store(
    _ authenticator: any Authenticator,
    identifier: String?,
    expirationTime: Date?
  ) async throws(TokenStorageError) {
    let payload: Data
    do {
      payload = try authenticator.encoded()
    } catch {
      throw TokenStorageError.storageFailed(reason: error.localizedDescription)
    }
    let entry = StoredEntry(
      storageKey: type(of: authenticator).storageKey,
      payload: payload,
      expirationTime: expirationTime
    )
    await storage.store(entry, identifier: identifier)
  }

  public func retrieve(
    identifier: String?
  ) async throws(TokenStorageError) -> (any Authenticator)? {
    guard let entry = await storage.retrieve(identifier: identifier) else {
      return nil
    }
    guard let factory = Self.factories[entry.storageKey] else {
      throw TokenStorageError.corruptedStorage
    }
    do {
      return try factory(entry.payload)
    } catch {
      throw TokenStorageError.corruptedStorage
    }
  }

  public func remove(identifier: String?) async throws(TokenStorageError) {
    await storage.remove(identifier: identifier)
  }

  public func listIdentifiers() async throws(TokenStorageError) -> [String] {
    await storage.listIdentifiers()
  }

  /// Clears all stored credentials.
  public func clear() async {
    await storage.clear()
  }

  /// Cleans up expired tokens from storage.
  public func cleanupExpiredTokens() async {
    await storage.cleanupExpiredTokens()
  }
}
