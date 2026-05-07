//
//  APITokenAuthenticator.swift
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

/// CloudKit API-token authentication: appends `ckAPIToken=...` as a query item.
///
/// Suitable for container-level access to the public database. Construct via
/// the throwing initializer so that an invalid token format is rejected before
/// the value can be used to authenticate a request.
public struct APITokenAuthenticator: Authenticator {
  public static let storageKey: String = "api-token"

  /// The 64-character hex CloudKit API token from Apple Developer Console.
  public let token: String

  public var defaultStorageIdentifier: String {
    "api-\(token.prefix(8))"
  }

  /// Creates an authenticator from an API token string.
  /// - Parameter token: The CloudKit API token.
  /// - Throws: `TokenManagerError.invalidCredentials` if the token is empty
  ///   or doesn't match the expected 64-character hex format.
  public init(token: String) throws(TokenManagerError) {
    guard !token.isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenEmpty)
    }
    let regex = NSRegularExpression.apiTokenRegex
    guard !regex.matches(in: token).isEmpty else {
      throw TokenManagerError.invalidCredentials(.apiTokenInvalidFormat)
    }
    self.token = token
  }

  public func authenticate(
    request: inout HTTPRequest,
    body: inout HTTPBody?
  ) async throws {
    request.appendQueryItems([URLQueryItem(name: "ckAPIToken", value: token)])
  }

  public func encoded() throws -> Data {
    try JSONEncoder().encode(WireFormat(token: token))
  }

  public init(decoding data: Data) throws {
    let wire = try JSONDecoder().decode(WireFormat.self, from: data)
    try self.init(token: wire.token)
  }

  private struct WireFormat: Codable {
    let token: String
  }
}
