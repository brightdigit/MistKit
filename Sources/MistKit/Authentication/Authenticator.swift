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

  /// Attaches this credential to the given HTTP request.
  ///
  /// - Parameters:
  ///   - request: The request to mutate (typically by adding query items
  ///     or headers).
  ///   - body: The request body. May be reassigned — for example,
  ///     `ServerToServerAuthenticator` consumes the body to compute a
  ///     signature and replaces it with a buffered copy so downstream
  ///     middleware sees the same bytes.
  func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws

  /// Serializes this authenticator's payload for persistence.
  func encoded() throws -> Data

  /// Reconstructs the authenticator from previously-encoded data.
  init(decoding data: Data) throws
}
