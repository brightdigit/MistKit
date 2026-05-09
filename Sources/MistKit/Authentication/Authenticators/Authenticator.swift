//
//  Authenticator.swift
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
public import HTTPTypes
public import OpenAPIRuntime

/// A value that knows how to apply a particular CloudKit authentication scheme
/// to an outgoing HTTP request.
///
/// Concrete authenticators (`APITokenAuthenticator`, `WebAuthTokenAuthenticator`,
/// `ServerToServerAuthenticator`) own both the credential payload and the rules
/// for attaching it to a request. The `AuthenticationMiddleware` simply asks the
/// current authenticator to apply itself; new authentication schemes can be
/// added without modifying the middleware.
///
/// `Authenticator` deliberately does not inherit `Equatable` or `Codable`:
/// either would impose a `Self` requirement and prevent its use as
/// `any Authenticator`, which storage and `TokenManager.currentAuthenticator()`
/// rely on. Hand-rolled `encoded()` / `init(decoding:)` keep on-disk format
/// decisions next to the type's invariants.
public protocol Authenticator: Sendable {
  /// Stable string identifier for routing decoded data back to the right
  /// concrete type. Storage stores authenticators as `[storageKey: Data]`.
  static var storageKey: String { get }

  /// Identifier used by storage when the caller doesn't supply one.
  ///
  /// Defaults to `Self.storageKey`. Concrete types override to provide a
  /// richer identifier (e.g. one derived from a token prefix or key ID),
  /// allowing multiple authenticators of the same type to coexist in
  /// storage under distinct keys.
  var defaultStorageIdentifier: String { get }

  /// Reconstructs the authenticator from previously-encoded data.
  init(decoding data: Data) throws

  /// Attaches this credential to the given HTTP request.
  ///
  /// - Parameters:
  ///   - request: The request to mutate (typically by adding query items
  ///     or headers).
  ///   - body: The request body. May be reassigned — for example,
  ///     `ServerToServerAuthenticator` consumes the body to compute a
  ///     signature and replaces it with a buffered copy so downstream
  ///     middleware sees the same bytes.
  /// - Throws: An error if the credential cannot be applied — for example,
  ///   `OpenAPIRuntime` errors when buffering the request body fails or
  ///   exceeds an authenticator-specific size limit.
  func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws

  /// Serializes this authenticator's payload for persistence.
  ///
  /// - Warning: The returned data may contain sensitive credential material
  ///   (API tokens, web auth tokens, raw P-256 private keys). Implementors
  ///   of `TokenStorage` are responsible for storing it securely —
  ///   typically encrypted at rest with appropriate ACLs.
  ///   `InMemoryTokenStorage` is suitable only for development and testing;
  ///   production deployments should provide a `TokenStorage` backed by
  ///   Keychain, a KMS, or an equivalent secret store.
  func encoded() throws -> Data
}

extension Authenticator {
  /// Default implementation: returns `Self.storageKey`. Override on the
  /// concrete type when a richer per-instance identifier is appropriate.
  public var defaultStorageIdentifier: String {
    Self.storageKey
  }
}
