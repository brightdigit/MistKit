//
//  InMemoryTokenStorage+Convenience.swift
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

// MARK: - Convenience Methods

extension InMemoryTokenStorage {
  /// Stores an authenticator with an automatic identifier derived from the
  /// concrete authenticator type.
  /// - Parameter authenticator: The authenticator to persist.
  /// - Throws: `TokenStorageError` if the storage operation fails.
  public func store(_ authenticator: any Authenticator) async throws {
    let identifier = Self.defaultIdentifier(for: authenticator)
    try await store(authenticator, identifier: identifier)
  }

  /// Retrieves the first stored authenticator with the given storage key.
  /// - Parameter storageKey: The storage key (`Authenticator.storageKey`) to
  ///   look up — e.g. `APITokenAuthenticator.storageKey`.
  /// - Returns: The first matching authenticator, or `nil` if none found.
  /// - Throws: `TokenStorageError` if retrieval fails.
  public func retrieve(byStorageKey storageKey: String) async throws(TokenStorageError)
    -> (any Authenticator)?
  {
    let identifiers = try await listIdentifiers()
    for identifier in identifiers {
      if let authenticator = try await retrieve(identifier: identifier),
        type(of: authenticator).storageKey == storageKey
      {
        return authenticator
      }
    }
    return nil
  }

  /// Lists all stored authenticators grouped by their storage key.
  public func authenticatorsByStorageKey() async throws -> [String: [any Authenticator]] {
    var result: [String: [any Authenticator]] = [:]
    let identifiers = try await listIdentifiers()
    for identifier in identifiers {
      if let authenticator = try await retrieve(identifier: identifier) {
        let key = type(of: authenticator).storageKey
        result[key, default: []].append(authenticator)
      }
    }
    return result
  }

  /// Default identifier scheme used by the no-identifier `store(_:)` overload.
  private static func defaultIdentifier(for authenticator: any Authenticator) -> String {
    if let api = authenticator as? APITokenAuthenticator {
      return "api-\(api.token.prefix(8))"
    }
    if let web = authenticator as? WebAuthTokenAuthenticator {
      return "web-\(web.apiToken.prefix(8))"
    }
    if #available(macOS 11.0, iOS 14.0, tvOS 14.0, watchOS 7.0, *),
      let s2s = authenticator as? ServerToServerAuthenticator
    {
      return "s2s-\(s2s.keyID)"
    }
    return type(of: authenticator).storageKey
  }
}
