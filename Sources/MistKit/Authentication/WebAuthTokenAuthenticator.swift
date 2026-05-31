//
//  WebAuthTokenAuthenticator.swift
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

/// CloudKit web-authentication: appends `ckAPIToken=...` and a
/// character-map-encoded `ckWebAuthToken=...` as query items.
///
/// Required for user-specific operations on the private database.
public struct WebAuthTokenAuthenticator: Authenticator {
  private struct WireFormat: Codable {
    let apiToken: String
    let webAuthToken: String
  }

  /// Stable storage key (`"web-auth-token"`).
  public static let storageKey: String = "web-auth-token"

  private static let encoder = CharacterMapEncoder()

  /// The 64-character hex CloudKit API token.
  public let apiToken: String

  /// The web authentication token issued by CloudKit JS.
  public let webAuthToken: String

  /// Identifier derived from the first 8 characters of `apiToken` so that
  /// distinct authenticated sessions can be persisted side by side.
  public var defaultStorageIdentifier: String {
    "web-\(apiToken.prefix(8))"
  }

  /// The web auth token after applying CloudKit's character-map encoding.
  public var encodedWebAuthToken: String {
    Self.encoder.encode(webAuthToken)
  }

  /// Creates an authenticator from API and web-auth tokens.
  /// - Parameters:
  ///   - apiToken: The CloudKit API token.
  ///   - webAuthToken: The web authentication token.
  /// - Throws: `TokenManagerError.invalidCredentials` if either token is
  ///   empty, the API token has the wrong format, or the web auth token is
  ///   too short.
  public init(
    apiToken: String,
    webAuthToken: String
  ) throws(TokenManagerError) {
    guard !apiToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenEmpty)
    }
    let regex = NSRegularExpression.apiTokenRegex
    guard !regex.matches(in: apiToken).isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenInvalidFormat)
    }
    guard !webAuthToken.isEmpty else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenEmpty)
    }
    guard webAuthToken.count >= 10 else {
      throw TokenManagerError.invalidCredentials(.webAuthTokenTooShort)
    }
    self.apiToken = apiToken
    self.webAuthToken = webAuthToken
  }

  /// Reconstructs a `WebAuthTokenAuthenticator` from data previously
  /// produced by `encoded()`. Re-runs format validation, so a corrupted
  /// or stale payload throws `TokenManagerError.invalidCredentials`.
  public init(decoding data: Data) throws {
    let wire = try JSONDecoder.shared.decode(WireFormat.self, from: data)
    try self.init(apiToken: wire.apiToken, webAuthToken: wire.webAuthToken)
  }

  /// Appends `ckAPIToken` and a character-map-encoded `ckWebAuthToken` as
  /// query items on the outgoing request.
  public func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws {
    let encoded = Self.encoder.encode(webAuthToken)
    request.appendQueryItems([
      URLQueryItem(name: "ckAPIToken", value: apiToken),
      URLQueryItem(name: "ckWebAuthToken", value: encoded),
    ])
  }

  /// JSON-encodes both tokens for persistence by `TokenStorage`.
  public func encoded() throws -> Data {
    try JSONEncoder.shared.encode(WireFormat(apiToken: apiToken, webAuthToken: webAuthToken))
  }
}
